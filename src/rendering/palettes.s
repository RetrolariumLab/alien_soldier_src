; Loads multiple palettes from a pointer table sequentially
Gfx_LoadMultiplePalettes:                               ; CODE XREF: StoryScreen_WaitForScrollAndLoadPalette+3C   p  ; was: sub_B900
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
Gfx_LoadMultiplePalettes_NextOffset:                    ; CODE XREF: Gfx_LoadMultiplePalettes+42   j  ; was: loc_B92E
                move.w  (a4)+,d0
                bne.s   Gfx_LoadPaletteFromRelativeOffset
                rts
; ---------------------------------------------------------------------------
; Resolves one signed command offset relative to the preserving loader entry
Gfx_LoadPaletteFromRelativeOffset:                      ; CODE XREF: Gfx_LoadMultiplePalettes+30   j  ; was: loc_B934
                ext.l   d0
                addi.l  #Gfx_LoadPalettePreservingSharedColor,d0
                movea.l d0,a0
                bsr.w   Gfx_LoadPaletteCommand
                bra.s   Gfx_LoadMultiplePalettes_NextOffset
; End of function Gfx_LoadMultiplePalettes
; ---------------------------------------------------------------------------
StoryScreenPaletteOffsetList:   dc.w    (CreditsAndEarlyStagePaletteCommandBank+$82)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: StoryScreen_WaitForScrollAndLoadPalette+36   o  ; was: word_B944
                dc.w    0
OptionsScreenPaletteOffsetList: dc.w    FrontendPaletteCommands-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: UI_InitOptionsScreen+72   o  ; was: word_B948
                dc.w    (FrontendPaletteCommands+$82)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
StageStartPaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$102)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: WeaponSetup_InitializeScreen+DC   o  ; was: word_B94E
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$128)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
WeaponSetupControlTestPaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$148)-Gfx_LoadPalettePreservingSharedColor
                                        ; DATA XREF: WeaponSetup_RenderControlTestRowsAndLoadPalette+32   o  ; was: word_B954
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
                                        ; DATA XREF: Continue_InitializeScreen+40   o
ResultsScreenPaletteOffsetList: dc.w    (StageReadyPaletteCommand+$6)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B96E
                dc.w    (StageReadyPaletteCommand+$C)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$12)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$18)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; DATA XREF: Results_InitializeFinalSummary+6C   o
FrontendTransitionPaletteOffsetLists:   dc.w    (CreditsAndEarlyStagePaletteCommandBank+$E2)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B978
                dc.w    0
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$16E)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1AE)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; DATA XREF: Frontend_InitializeTransitionScene+16   o
CreditsAndPlanetPaletteOffsetList:  dc.w    (Boss_Epsilon1PaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: EndingSequence_Initialize+5E   o  ; was: word_B982
                dc.w    (Boss_Epsilon1PaletteCommands+$60)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; EndingPlanet_Initialize+20   o
EarlyStagePaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1C4)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage1ConfigRecord   o  ; was: word_B988
                dc.w    0
                                        ; ROM:Stage2ConfigRecord   o
ShellshogunStagePaletteOffsetList:  dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1C4)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: Camera_ShellshogunBossInit+38   o  ; was: word_B98C
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$206)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage4ConfigRecord   o
Stage5To7PaletteOffsetList: dc.w    (CreditsAndEarlyStagePaletteCommandBank+$228)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage5ConfigRecord   o  ; was: word_B992
                dc.w    0
                                        ; ROM:Stage6ConfigRecord   o
                                        ; ROM:Stage7ConfigRecord   o
Stage8InitialPaletteOffsetList: dc.w    (CreditsAndEarlyStagePaletteCommandBank+$26A)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage8ConfigRecord   o  ; was: word_B996
                dc.w    0
XiTigerAndStage9PaletteOffsetList:  dc.w    (CreditsAndEarlyStagePaletteCommandBank+$26A)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:XiTigerStageConfigRecord   o  ; was: word_B99A
                dc.w    (Boss_FlyingNeoPaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage9ConfigRecord   o
XiTigerCutscenePaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$E)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: XiTigerCutscene_LoadAssets+C   o  ; was: word_B9A0
                dc.w    0
Stage10To13PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$4E)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage10ConfigRecord   o  ; was: word_B9A4
                dc.w    0
                                        ; ROM:Stage11ConfigRecord   o
                                        ; ROM:Stage12ConfigRecord   o
                                        ; ROM:Stage13ConfigRecord   o
Stage14To16PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$8E)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage14ConfigRecord   o  ; was: word_B9A8
                dc.w    0
                                        ; ROM:Stage15ConfigRecord   o
                                        ; ROM:Stage16ConfigRecord   o
Stage17PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$CE)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage17BossConfigRecord   o  ; was: word_B9AC
                dc.w    0
Stage18And19PaletteOffsetList:  dc.w    (Stage17PaletteCommandBank+$20)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage18ConfigRecord   o  ; was: word_B9B0
                dc.w    0
                                        ; ROM:Stage19ConfigRecord   o
UnreferencedStage20VariantPaletteOffsetList:    dc.w    (Stage17PaletteCommandBank+$60)-Gfx_LoadPalettePreservingSharedColor
                                        ; DATA XREF: ROM:UnreferencedStage20Variant1ConfigRecord   o  ; was: word_B9B4
                dc.w    0
                                        ; ROM:UnreferencedStage20Variant2ConfigRecord   o
                                        ; ROM:UnreferencedStage20Variant3ConfigRecord   o
                                        ; ROM:UnreferencedStage20Variant4ConfigRecord   o
Stage20PaletteOffsetLists:  dc.w    (Stage17PaletteCommandBank+$A0)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage20ConfigRecord   o  ; was: word_B9B8
                dc.w    0
                dc.w    SevenForceArtemisTransitionPaletteCommand-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
SevenForceCutscenePaletteOffsetList:    dc.w    (SireneAndLateStagePaletteCommandBank+$1E)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: Cutscene_SevenForceLoadGraphics   o  ; was: word_B9C0
                dc.w    (SireneAndLateStagePaletteCommandBank+$3E)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
Stage21And23PaletteOffsetList:  dc.w    (SireneAndLateStagePaletteCommandBank+$46)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage21ConfigRecord   o  ; was: word_B9C6
                dc.w    (Stage15PaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage23ConfigRecord   o
Stage22PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$46)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage22ConfigRecord   o  ; was: word_B9CC
                dc.w    DestroyerProtoIntroPaletteCommands-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
Stage24PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$86)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage24ConfigRecord   o  ; was: word_B9D2
                dc.w    (DestroyerProtoIntroPaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
UnreferencedFlaggedPaletteOffsetListA:  dc.w    $718, $E34, 0  ; DATA XREF: ROM:UnreferencedFlaggedConfigRecordA   o  ; was: word_B9D8
UnreferencedFlaggedPaletteOffsetListB:  dc.w    $738, 0  ; DATA XREF: ROM:UnreferencedFlaggedConfigRecordB   o  ; was: word_B9DE
Stage25PaletteOffsetList:               dc.w    (SireneAndLateStagePaletteCommandBank+$E6)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage25ConfigRecord   o  ; was: word_B9E2
                dc.w    0
Stage26PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$126)-Gfx_LoadPalettePreservingSharedColor  ; DATA XREF: ROM:Stage26ConfigRecord   o  ; was: word_B9E6
                dc.w    0
                                        ; ZLeoEnding_InitializeScene+24   o

; Loads a palette command while preserving the shared color at palette slot $36
Gfx_LoadPalettePreservingSharedColor:                   ; CODE XREF: Boss_LoadAssetSet+6C   p  ; was: sub_B9EA
                                        ; Stage_LoadStage17Palettes+12   j
                move.w  (PaletteShadowColor54).w,(PaletteColorPair).w
                bsr.s   Gfx_LoadPaletteCommand
                move.w  (PaletteColorPair).w,(PaletteActiveColor54).w
                move.w  (PaletteColorPair).w,(PaletteShadowColor54).w
                rts
; End of function Gfx_LoadPalettePreservingSharedColor
; Command header: destination byte, inclusive word count, then CRAM words
; The destination byte selects matching target and shadow buffers $80 bytes apart
Gfx_LoadPaletteCommand:                                 ; CODE XREF: RegionRestricted+2A   p  ; was: LoadPalette
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
Gfx_LoadPaletteCommand_CopyColors:                      ; CODE XREF: Gfx_LoadPaletteCommand+24   j  ; was: loc_BA20
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                dbf     d7,Gfx_LoadPaletteCommand_CopyColors
                rts
; End of function Gfx_LoadPaletteCommand
; ---------------------------------------------------------------------------
CommonPaletteCommand:   dc.b    $42, $E, 0, 0, $E, $EE, 0, $EE, 0, $AE, 0, $6E, 0, $E, 0, 4  ; was: byte_BA2A
                                        ; DATA XREF: Gfx_LoadMultiplePalettes+24   o
                dc.b    0, $48, 2, $20, 4, $42, 8, $86, $C, $CA, 6, 0, 8, $40, $C, $84
FrontendPaletteCommands:    dc.b    0, $3F, 0, 0, 0, $60, $C, $EA, 0, 0, 0, 0, 0, 0, 0, 0  ; was: byte_BA4A
                                        ; DATA XREF: RegionRestricted+24   o
                                        ; StoryTitle_SetupLogoReveal+78   o
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 6, 0, $E, $EC, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 2, 0, 2, $22, $C, $22, $E, $42, 0, $E0, 0, 0
                dc.b    $E, $22, $E, $EE, 0, $6E, $A, $EE, 0, $28, 0, 4, $C, $EE, 0, 0
                dc.b    0, $CE, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 6, 0, 8
                dc.b    0, $A, 0, $C, 0, $2E, 0, $4E, 0, 0, 8, 0, $E, $62, $E, $CA
                dc.b    0, 0, 2, 1, 0, 4, 0, $8E
StageReadyPaletteCommand:   dc.b    $42, 1, 0, 2, 0, $6E, 2, 1, 6, 0, $E, $80, $22, 1, 4, 0  ; was: byte_BAD2
                                        ; DATA XREF: StageReady_Initialize+38   o
                dc.b    8, $40, $42, 1, 6, 0, $E, $EC, $62, 1, 0, 6, 0, $AE
PostStageFullPaletteCommand:    dc.b    0, $3F, 0, 0, 0, $20, 2, $E6, 0, $2E, 0, $E, 0, 8, 0, 4  ; was: byte_BAF0
                                        ; DATA XREF: Results_InitializePostStageFlow+7E   o
                                        ; Results_InitializeSecondaryOptionsReturn+50   o
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 4, $22, 0, $4C, 0, $2A, 0, 8, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 6, 0, $E, $EC, $C, $AA, $A, $88, 8, $66, 6, $44
                dc.b    4, $22, 0, $A, 0, 0, $A, $AA, 6, $66, 2, $22, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 6, 0, $AE, 0, $26, 0, 4, 0, 2, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0
CreditsAndEarlyStagePaletteCommandBank: binclude "data/mappings/byte_BB72.bin"  ; was: byte_BB72
CreditsAndEarlyStagePaletteCommandBank_End:
FlyingNeoAndMidgamePaletteCommandBank:  binclude "data/other/byte_BE1E.bin"  ; was: byte_BE1E
FlyingNeoAndMidgamePaletteCommandBank_End:
Stage17PaletteCommandBank:              dc.b    $62, $E, 2, 0, $E, $EE, 0, $6E, 6, $EE, 2, $84, 8, $EA, $C, $EE  ; was: byte_BF2C
                                        ; DATA XREF: Stage_LoadStage17Palettes   o
                dc.b    4, 0, 6, $20, 8, $42, $A, $64, $C, $86, $E, $A8, $E, $CA, $E, $EE
                dc.b    2, $1E, $E, $EE, $E, $AA, $A, $68, $A, $44, 8, $22, 4, $22, $E, $86
                dc.b    $E, $64, $E, $42, $A, $86, 6, $42, 2, $20, 2, 0, 0, 0, 0, $24
                dc.b    0, 0, $E, $EE, $E, $CC, $E, $AA, $C, $66, 8, $44, 4, $22, 6, $88
                dc.b    4, $66, 2, $44, 0, $22, 0, 0, 2, $68, 0, $46, 0, $24, $E, $EE
                dc.b    2, $1E, 0, $20, $E, $EC, 2, $62, $E, $EC, $E, $CA, $A, $84, 8, $62
                dc.b    4, $40, 2, $20, 0, $22, 2, $46, 2, $8A, 4, $CC, 6, $40, $E, $84
                dc.b    0, 0, $C, $CC, $A, $88, 2, 0, 2, 2, 4, $24, 0, 2, 0, $20
                dc.b    4, $64, 2, $48, 4, $8C, 0, $24, 4, $20, 6, $42, 8, $66, 0, $2A
                dc.b    2, $1E, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, 8, $86, $E, $EC, $C, $CA
                dc.b    $E, $EC, $E, $EE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                dc.b    2, $22, $E, $CC, 2, $24, 2, $66, 4, $88, $C, $CC, 0, $44, 8, $AA
                dc.b    4, $46, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, 2, $44, 2, $42
SevenForceSylpheedTransitionPaletteCommand: dc.b    $22, 6, 8, $CC, 2, $44, 4, $66, 6, $88, 8, $AA, 4, $66, 6, $88  ; was: byte_C00C
                                        ; DATA XREF: Entity_StartSevenForceSylpheedTransition+16   o
SevenForceArtemisTransitionPaletteCommand:  dc.b    2, $1E, 0, 0, 0, $22, 2, $42, 6, $64, 0, $22, 2, $44, 4, $66  ; was: byte_C01C
                                        ; DATA XREF: Entity_StartSevenForceArtemisTransition+1C   o
                dc.b    6, $88, $FF, $FF, 0, $22, 2, $44, 2, $66, 4, $AC, $A, $CE, $FF, $FF
                dc.b    0, 0, 0, 0, 2, 0, 2, $22, 6, $44, 2, 0, 4, 0, 6, 0
                dc.b    6, $20, 8, $42, $A, $64, $C, $86, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
SireneAndLateStagePaletteCommandBank:   binclude "data/other/byte_C05C.bin"  ; was: byte_C05C
SireneAndLateStagePaletteCommandBank_End:
SharedStagePaletteCommand:              dc.b    $62, $E, 0, 0, $E, $EE, $E, $A8, 0, 6, 0, $2A, 0, 0, 4, $6E  ; was: byte_C1A2
                                        ; DATA XREF: Stage_LoadStage1VisualAssets   o
                                        ; sub_11EAA   o
                dc.b    0, $46, 2, $8A, 6, $CC, 2, $24, 4, $6A, 8, $AE, 6, $22, $A, $62
XiTigerCutscenePaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, 0, $EE, 0, $AE, 0, $6E, 0, $E, 0, 4  ; was: byte_C1C2
                                        ; DATA XREF: Cutscene_XiTigerActorSetup   o
                dc.b    0, $48, 2, $20, 4, $42, 8, $86, $C, $CA, 6, 0, 8, $40, $C, $84
Stage15PaletteCommands: dc.b    $62, $E, $E, $EE, $F, $FF, $A, $26, $A, $AA, 8, $88, $F, $FF, 6, $66  ; was: byte_C1E2
                                        ; DATA XREF: Stage_LoadStage15VisualAssets+6   o
                dc.b    4, $44, 2, $22, $C, $AA, $A, $88, 8, $66, 6, $44, 4, $22, 0, 0
                dc.b    $62, 6, 0, 0, 2, $22, 2, $44, 4, $68, 8, $AC, 0, 0, $A, $CC
DestroyerProtoIntroPaletteCommands: dc.b    $62, $E, $E, $EE, $E, $AA, $A, $66, 6, $22, 4, 0, 0, 0, 0, $AE  ; was: byte_C212
                                        ; DATA XREF: StageTransition_InitializeDestroyerProtoBackdrop+1C   o
                dc.b    0, $6C, 0, $28, 0, 0, 0, 4, 8, $CC, 6, $88, 4, $46, 2, $22
                dc.b    $22, $E, $E, $EE, $E, $AA, $A, $66, 6, $22, 4, 0, 0, 0, 0, $AE
                dc.b    0, $6C, 0, $28, 0, 0, 0, 4, 8, $CC, 6, $88, 4, $46, 2, $22
Boss_JetsripperPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $C, $AA, $A, $88, 0, 0, 2, 2  ; was: byte_C252
                                        ; DATA XREF: ROM:Boss_JetsripperAssetSet   o
                dc.b    6, 4, $C, $48, 2, $24, 4, $46, 4, $AA, 0, $A, 0, 6, 0, 2
Boss_AntroidPaletteCommand: dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $C, $AA, $A, $88, 0, 0, 0, 4  ; was: byte_C272
                                        ; DATA XREF: ROM:Boss_AntroidAssetSet   o
                dc.b    0, $26, 0, $4A, 0, $6C, 2, $AE, 2, $22, 4, $44, 0, $2A, 4, $6E
Boss_ShellshogunPaletteCommand: dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $C, $AA, $A, $88, 0, 0, 2, 4  ; was: byte_C292
                                        ; DATA XREF: ROM:Boss_ShellshogunAssetSet   o
                dc.b    0, $2A, 2, $6E, 4, $40, 0, $88, 8, $CC, 2, $24, 0, $48, 6, $8C
Boss_SniperHoneyviperPaletteCommand:    dc.b    $62, $E, 0, 0, $C, $EE, $C, $CC, $A, $AA, 6, $66, 0, 0, 4, $8C  ; was: byte_C2B2
                                        ; DATA XREF: ROM:Boss_SniperHoneyviperAssetSet   o
                dc.b    2, $6A, 0, $48, 0, $26, 4, $6A, 2, $2A, 0, 4, 8, $88, 4, $44
Boss_MadamBarbarPaletteCommand: dc.b    $62, $E, 2, 2, $C, $EE, $A, $AA, 8, $88, 6, $66, 0, 0, 2, 4  ; was: byte_C2D2
                                        ; DATA XREF: ROM:Boss_MadamBarbarAssetSet   o
                dc.b    0, 8, 0, $C, 0, $4E, 8, $8E, 0, 6, 0, $48, 2, $8A, 4, $CC
Boss_JokerPaletteCommand:   dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $E, $AA, $E, $88, 0, 0, 4, $22  ; was: byte_C2F2
                                        ; DATA XREF: ROM:Boss_JokerAssetSet   o
                dc.b    6, $44, $C, $68, 2, 6, 4, $2C, 8, $8E, 0, $42, 2, $84, 2, $CA
Boss_TerobusterPaletteCommand:  dc.b    $62, $D, 2, 2, $E, $EE, $A, $AA, 8, $88, 6, $66, 0, 0, 2, $22  ; was: byte_C312
                                        ; DATA XREF: ROM:Boss_TerobusterAssetSet   o
                dc.b    4, $24, 8, $42, $C, $60, $E, $C0, 0, $CE, 0, $6A, 0, $26
Boss_FlyingNeoPaletteCommands:  dc.b    $62, $E, 0, 2, $C, $EE, 0, 0, 0, 0, 8, $66, 0, 0, 6, $20  ; was: byte_C330
                                        ; DATA XREF: Boss_FlyingNeoSetup+D0   o
                dc.b    2, 0, 4, $22, 0, 6, 0, $2A, 2, $6E, 0, $24, 2, $68, 6, $AC
                dc.b    $62, $E, 2, 0, $C, $CC, 0, 0, 0, 0, $A, $88, 0, 0, 8, $46
                dc.b    4, $24, 2, 2, 4, 2, $A, 6, 8, $6A, 4, $88, 2, $44, 0, $22
Boss_XiTigerPaletteCommand: dc.b    $62, $E, 2, 0, $E, $EE, 0, 0, 0, 0, 0, 0, 0, 0, $C, $CA  ; was: byte_C370
                                        ; DATA XREF: ROM:Boss_XiTigerAssetSet   o
                dc.b    $A, $A6, $A, $64, 6, $42, 4, $8C, 0, $48, 0, 4, 2, $AC, 0, $46
Boss_DeepStriderPaletteCommand: dc.b    $62, $E, 0, 0, $E, $EE, 8, $88, $E, $AA, $E, $88, $F, $FF, 4, 0  ; was: byte_C390
                                        ; DATA XREF: ROM:Boss_DeepStriderAssetSet   o
                dc.b    6, $20, 8, $40, $A, $62, $C, $A4, 2, 4, 2, 8, 2, $C, 4, $4E
Boss_GustheadPaletteCommand:    dc.b    $62, $E, 0, 0, $E, $EE, $C, $AA, $A, $88, 8, $66, $F, $FF, 6, $44  ; was: byte_C3B0
                                        ; DATA XREF: ROM:Boss_GustheadAssetSet   o
                dc.b    4, $22, 4, 0, $A, $22, $E, $66, 0, $24, 0, $46, 0, $8A, 0, $CE
Boss_SharpsteelPaletteCommand:  dc.b    $62, $E, 0, 0, $C, $EC, 8, $C8, 6, $64, 2, $20, $F, $FF, 8, $EE  ; was: byte_C3D0
                                        ; DATA XREF: ROM:Boss_SharpsteelAssetSet   o
                dc.b    4, $AA, 0, $66, 0, $22, 0, 4, 0, $28, 0, $4C, 4, $8E, 8, $CE
Boss_SnakePaletteCommand:   dc.b    $62, 8, 0, 0, $E, $EE, 8, $CE, 6, $8C, 6, $6C, $F, $FF, 4, $26  ; was: byte_C3F0
                                        ; DATA XREF: Stage_LoadStage13Palette   o
                dc.b    2, 2, 4, $4A
EntityType1C0PaletteCommand:    dc.b    $62, $E, 0, 2, $E, $EE, $A, $AA, 6, $66, 2, $22, $F, $FF, $A, $EE  ; was: byte_C404
                                        ; DATA XREF: ROM:EntityType1C0AssetSet   o
                                        ; Identity beyond entity type $1C0 is unproven
                dc.b    8, $CE, 6, $8C, 4, $6A, 2, $48, 0, $26, 0, 4, 0, 0, 0, $A
Boss_VictorPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $E, $AA, $E, $88, $FF, $FF, $A, $46  ; was: byte_C424
                                        ; DATA XREF: ROM:Boss_VictorAssetSet   o
                dc.b    6, 2, 6, $6E, 4, $2C, 2, 8, 2, 4, 2, $26, 0, $48, 0, $8C
Boss_SunsetStingPaletteCommand: dc.b    $62, $E, 0, 0, $E, $EE, $E, $CC, $E, $AA, $E, $88, $F, $FF, 0, 6  ; was: byte_C444
                                        ; DATA XREF: ROM:Boss_SunsetStingAssetSet   o
                dc.b    0, $2A, 4, $6E, 0, $22, 2, $44, 2, $88, 0, $26, 0, $48, 0, $8C
Boss_ViblackIntroPaletteCommand:    dc.b    2, $E, 0, 2, 0, $26, 0, $6A, 0, 0, 0, 0, 0, 0, 2, $AE  ; was: byte_C464
                                        ; DATA XREF: Boss_ViblackInit+9A   o
                dc.b    4, $20, 6, $42, $A, $64, $C, $A8, $E, $CA, $E, $EC, 0, 0, $E, $EE
Boss_ViblackPostBattlePaletteCommand:   dc.b    2, $E, 0, 2, 4, 6, 6, $28, 0, 0, 0, 0, 2, 0, 8, $4A  ; was: byte_C484
                                        ; DATA XREF: Boss_ViblackFinishTransitionState+3C   o
                dc.b    2, $20, 4, $42, 6, $66, 8, $88, $A, $AA, $A, $CC, 0, 0, $A, $AA
ViblackPostBattleScrollPaletteCommand:  dc.b    $22, $B, $E, $CA, $E, $C8, $E, $A6, $E, $84, $C, $62, $A, $40, 8, $20  ; was: byte_C4A4
                                        ; DATA XREF: Stage16_UpdatePostViblackCameraAndPalette+3E   o
                dc.b    6, 0, 4, 0, 2, 0, 2, 0, 2, 0
Boss_BackStringerPaletteCommand:    dc.b    $62, $E, 2, 0, $C, $EE, 2, $26, 8, $8A, 0, $24, $F, $FF, 0, $46  ; was: byte_C4BE
                                        ; DATA XREF: ROM:Boss_BackStringerAssetSet   o
                dc.b    2, $8A, 6, $CE, 0, $6E, 0, $2C, 0, 6, $F, $FF, 6, $68, $A, $AC
Boss_Epsilon1PaletteCommands:   dc.b    $62, $E, 2, 0, 4, 4, 6, $26, 8, $4A, $A, $6C, $F, $FF, $C, $AE  ; was: byte_C4DE
                                        ; DATA XREF: ROM:Boss_Epsilon1AssetSet   o
                                        ; Stage_LoadStage17Palettes+C   o
                dc.b    $C, $CE, 0, $22, $E, $EE, 0, $46, 4, $8A, 6, $EE, 0, 0, 0, 0
                dc.b    2, $1E, 0, 0, 0, $22, 2, $44, $E, $EE, $A, $EA, 6, $E6, 2, $C2
                dc.b    0, $80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, $24, 0, $46, 0, $68, 2, $8A, 4, $42, 6, $64
                dc.b    8, $86, $A, $AA, $E, $EE, 4, 0, 8, $22, $C, $66, $E, $88, 2, $20
                dc.b    $62, $E, 0, 0, $E, $EE, $E, $EC, $E, $A8, $E, $86, $E, $64, $E, $EC
                dc.b    $E, $CA, $E, $A8, $E, $86, $E, $64, $C, $42, $A, $20, 6, $20, 4, 0
Boss_JampanPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, $C, $CC, $A, $AA, 8, $88, $F, $FF, 6, $66  ; was: byte_C55E
                                        ; DATA XREF: ROM:Boss_JampanAssetSet   o
                                        ; Boss_JampanReinitializePostDefeatObjectsState+6   o
                dc.b    0, $A, 0, $E, 2, 4, 2, $26, 2, $48, 4, $6A, 6, $8C, 8, $AE
Boss_DestroyerMk2PaletteCommand:    dc.b    $62, $E, 0, 0, $E, $EE, 6, $E4, 0, $80, 0, $28, $F, $FF, 0, $6C  ; was: byte_C57E
                                        ; DATA XREF: ROM:Boss_DestroyerMk2AssetSet   o
                dc.b    0, $EA, 4, $22, 4, $46, 4, $88, 8, $CC, 0, 6, 2, $C, 6, $6E
Boss_BugmaxPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, 6, $AC, 4, $8A, 2, $68, $F, $FF, 2, $46  ; was: byte_C59E
                                        ; DATA XREF: ROM:Boss_BugmaxAssetSet   o
                dc.b    0, $24, 2, 6, 2, $2A, 2, $6C, 0, 0, 2, 2, 6, $24, 8, $68
EntityType3ECPaletteCommand:    dc.b    $62, $E, 0, 0, $E, $EE, $A, $AC, 2, $AC, 8, $EE, $F, $FF, 0, $48  ; was: byte_C5BE
                                        ; DATA XREF: ROM:EntityType3ECAssetSet   o
                                        ; Selected by the dormant Stage 18 late-phase path
                dc.b    0, 4, 2, 4, 2, $A, $C, $8E, 2, 2, 6, $44, $A, $A8, $E, $CA
EntityType3F0PaletteCommand:    dc.b    $62, $E, 0, 0, $E, $EE, 0, 6, 0, $48, 0, $8C, $F, $FF, 4, 0  ; was: byte_C5DE
                                        ; DATA XREF: ROM:EntityType3F0AssetSet   o
                                        ; Selected by the dormant Stage 18 late-phase path
                dc.b    $A, 0, $E, $20, $E, $60, $C, $AA, 8, $66, 6, $44, 4, $22, 0, $2E
EntityType3F4PaletteCommands:   dc.b    $62, $E, 0, 0, $E, $EE, $E, $CA, $C, $86, $A, $42, $F, $FF, 4, 0  ; was: byte_C5FE
                                        ; DATA XREF: ROM:EntityType3F4AssetSet   o
                                        ; Selected by the dormant Stage 18 late-phase path
                dc.b    2, 2, 2, 6, 4, $2A, $A, $6E, 6, $CC, 2, $8A, 0, $46, 8, $20
                dc.b    $62, $E, 0, 0, $E, $EE, 2, 2, 4, $24, 6, $46, $F, $FF, 8, $68
                dc.b    $A, $8A, $C, $AC, $E, $CE, 0, 4, 0, 8, 0, $C, 2, $4E, 6, $8E
EntityType3FCPaletteCommands:   dc.b    $62, $E, 0, 0, $E, $EE, 2, $20, 4, $42, 4, $64, $F, $FF, 6, $AA  ; was: byte_C63E
                                        ; DATA XREF: ROM:EntityType3FCAssetSet   o
                                        ; Identity beyond entity type $3FC is unproven
                dc.b    4, $CE, 2, $8C, 2, $6A, 2, $46, 4, $24, 4, $44, 6, $66, $A, $AA
                dc.b    $62, $E, 0, 0, $E, $EE, 8, $6E, 4, $2C, 2, 8, $F, $FF, 2, $24
                dc.b    0, $46, 2, $8A, 6, $CC, 0, $6E, 0, $2C, 0, 6, 2, 4, $A, $86
SevenForceValkiriePaletteCommand:   dc.b    $62, $E, 2, 4, $E, $EE, $A, $CA, 4, $66, 0, $44, $F, $FF, 2, $CE  ; was: byte_C67E
                                        ; DATA XREF: ROM:SevenForceValkirieAssetSet   o
                dc.b    0, $8C, 0, $8E, 0, $4C, 0, $2A, 2, 8, 0, $68, 6, $AE, $A, $EE
SevenForceMedusaPaletteCommand: dc.b    $62, $E, 6, 0, $E, $EE, 6, $66, 4, $44, 4, $42, $F, $FF, $A, $AA  ; was: byte_C69E
                                        ; DATA XREF: ROM:SevenForceMedusaAssetSet   o
                dc.b    8, $66, $E, $48, $C, $26, $A, $24, 8, 2, 0, $26, 0, $8C, $E, $AC
SevenForceSylpheedPaletteCommand:   dc.b    $62, $E, 2, $20, $E, $EE, 2, $8C, 0, $46, 2, $42, $F, $FF, 0, $C8  ; was: byte_C6BE
                                        ; DATA XREF: ROM:SevenForceSylpheedAssetSet   o
                dc.b    0, $84, 4, $C6, 2, $84, 0, $62, 0, $42, 0, $40, 0, $6C, 4, $EA
SevenForceArtemisPaletteCommand:    dc.b    $62, $E, 4, 2, $E, $EE, 6, $6C, 4, $48, 2, $24, $F, $FF, $A, $8A  ; was: byte_C6DE
                                        ; DATA XREF: ROM:SevenForceArtemisAssetSet   o
                dc.b    6, $68, $C, $CA, $A, $88, 8, $66, 2, $22, 0, $28, 0, $6E, $C, $CC
SevenForceSirenePaletteCommand: dc.b    $62, $E, 2, 2, $E, $EE, 6, $EE, 2, $8A, 2, $22, $F, $FF, $E, $A8  ; was: byte_C6FE
                                        ; DATA XREF: ROM:SevenForceSireneAssetSet   o
                dc.b    $A, $64, $E, $A8, $E, $62, $C, $22, 8, 2, 4, 2, 4, $84, $E, $EC
SevenForceSireneTimedPaletteCommandA:   dc.b    $62, $E, 0, 2, $E, $EE, $E, $A4, 8, $62, 4, $22, $F, $FF, 0, $AC  ; was: byte_C71E
                                        ; DATA XREF: ROM:SevenForceSireneTimedAssetSetA   o
                dc.b    0, $46, 4, $8E, 0, $4E, 0, $A, 0, 6, 0, 2, 0, $6C, 4, $EE
SevenForceSireneTimedPaletteCommandB:   dc.b    $62, $E, 2, $22, $E, $EC, 0, $6C, 0, $26, 2, $22, $F, $FF, 4, $86  ; was: byte_C73E
                                        ; DATA XREF: ROM:SevenForceSireneTimedAssetSetB   o
                dc.b    2, $44, $A, $44, 4, $20, 2, 2, 2, 0, 0, 2, 0, $AE, 8, $AA
Boss_DestroyerProtoPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, 6, $E4, 0, $80, 0, $28, $F, $FF, 0, $6C  ; was: byte_C75E
                                        ; DATA XREF: ROM:Boss_DestroyerProtoAssetSet   o
                dc.b    0, $AE, 4, $22, 4, $46, 4, $88, 8, $CC, 0, 6, $C, $60, $E, $A6
Boss_ShieldViperPaletteCommand: dc.b    $62, $E, 0, 0, $A, $EE, 4, $CE, 0, $6C, 0, $2A, $F, $FF, 0, 6  ; was: byte_C77E
                                        ; DATA XREF: ROM:Boss_ShieldViperAssetSet   o
                dc.b    2, $8E, 0, $4E, 0, $E, 0, $A, 2, 6, $E, $EE, $A, $24, $E, $A4
Boss_WolfGaropaPaletteCommand:  dc.b    $62, $E, 2, 0, $E, $EE, $E, $EC, $C, $AA, 8, $88, $F, $FF, 4, $44  ; was: byte_C79E
                                        ; DATA XREF: ROM:Boss_WolfGaropaAssetSet   o
                dc.b    2, $22, 0, $24, 0, $48, 2, $8E, 4, 2, 8, $24, $C, $6A, 0, $E
Boss_MissirayPaletteCommand:    dc.b    $62, $E, $E, $EE, $C, $AA, $A, $64, 8, $22, 4, 0, $F, $FF, 8, $CC  ; was: byte_C7BE
                                        ; DATA XREF: ROM:Boss_MissirayAssetSet   o
                dc.b    4, $88, 2, $44, 2, $22, 8, $6E, 2, $E, 0, 6, 0, 0, $F, $FF
Boss_ZLeoPaletteCommands:   dc.b    $62, $E, 0, 0, $E, $EE, $E, $88, 8, $44, 4, $22, $F, $FF, 2, 0  ; was: byte_C7DE
                                        ; DATA XREF: ROM:Boss_ZLeoAssetSet   o
                dc.b    0, 2, 0, 4, 0, $24, 0, $46, 2, $68, 4, $AC, 6, $CE, 0, $AE
                dc.b    $62, $E, 0, 0, $E, $EE, $F, $FF, $F, $FF, 0, $28, 0, 8, 0, $6C
                dc.b    0, $AE, 4, 2, 6, $24, 8, $46, $C, $8A, 0, 6, 2, $C, 6, $6E
SevenForceIntroPaletteCommand:  dc.b    $62, $E, 0, 0, $E, $EE, $A, $CE, 4, $8C, 2, $68, $FF, $FF, $A, $AA  ; was: byte_C81E
                                        ; DATA XREF: Entity_InitSevenForceIntro+36   o
                dc.b    6, $66, $E, $CC, $C, $AA, 8, $66, 6, $42, 4, $22, $E, $CC, $FF, $FF

; Main stage dispatcher jump table
