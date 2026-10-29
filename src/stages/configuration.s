Sys_InitStageState:                                     ; CODE XREF: Stage_UpdateGameplayEntry+32   p  ; was: sub_1221C
                clr.w   (TransitionModeOffset).w
                jsr     (Stage_InitializationNoOpHook).l
                bsr.w   Weapon_ClearAmmoRegenTimers
                clr.w   (FrameSkipLevel).w
                move.w  (WeaponStateIndex).w,d0
                beq.s   Stage_UseDefaultWeaponState
                cmpi.w  #$10,d0
                bpl.s   Stage_UseDefaultWeaponState
                asl.w   #1,d0
                move.w  d0,(WeaponIconTransferState).w
                bra.s   Stage_RunSelectedInitializerAndInitializePlayer
; ---------------------------------------------------------------------------
Stage_UseDefaultWeaponState:                            ; CODE XREF: Sys_InitStageState+16   j  ; was: loc_12242
                                        ; Sys_InitStageState+1C   j
                move.w  #2,(WeaponStateIndex).w
                move.w  #4,(WeaponIconTransferState).w
Stage_RunSelectedInitializerAndInitializePlayer:        ; CODE XREF: Sys_InitStageState+24   j  ; was: loc_1224E
                bsr.s   Stage_DispatchInitializer
                jsr     (UI_QueueAllWeaponIconTransfers).l
                jmp     Player_InitializeStats
; End of function Sys_InitStageState
; Dispatches to stage-specific initialization routine
Stage_DispatchInitializer:                              ; CODE XREF: Sys_InitStageState:Stage_RunSelectedInitializerAndInitializePlayer   p  ; was: sub_1225C
                move.w  (StageTableIndex).w,d0
                movea.w Stage_InitializerOffsets(pc,d0.w),a0
                adda.l  #Weapon_ClearAmmoRegenTimers,a0
                jmp     (a0)
; End of function Stage_DispatchInitializer
; ---------------------------------------------------------------------------
Stage_InitializerOffsets:   dc.w    Stage_ApplyStage1Configuration-Weapon_ClearAmmoRegenTimers  ; was: off_1226C
                                        ; DATA XREF: Stage_DispatchInitializer+4   r
                dc.w    Stage_ApplyStage2Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage3Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage4Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage5Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage6Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage7Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage8-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage9-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage10Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage11Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage12Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage13Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage14Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage15Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage16-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage17Boss-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage18-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage19-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage20-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage21-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage22-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_InitializeStage23-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage24Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage25Configuration-Weapon_ClearAmmoRegenTimers
                dc.w    Stage_ApplyStage26Configuration-Weapon_ClearAmmoRegenTimers

; Clears the four per-slot ammunition-regeneration timers
Weapon_ClearAmmoRegenTimers:                            ; CODE XREF: Stage_InitializeXiTigerState+A   p  ; was: sub_122A0
                                        ; Sys_InitStageState+A   p
                                        ; DATA XREF:
                movea.w #(WeaponAmmoRegenTimers-M68K_RAM),a0
                moveq   #3,d7
Weapon_ClearNextAmmoRegenTimer:                         ; CODE XREF: Weapon_ClearAmmoRegenTimers+8   j  ; was: loc_122A6
                clr.w   (a0)+
                dbf     d7,Weapon_ClearNextAmmoRegenTimer
                rts
; End of function Weapon_ClearAmmoRegenTimers
; Initializes stage 1 data structure and palette
Stage_ApplyStage1Configuration:                         ; DATA XREF: ROM:Stage_InitializerOffsets   o  ; was: sub_122AE
                lea     Stage1ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage1Configuration
; Initializes stage 2 data structure and palette
Stage_ApplyStage2Configuration:                         ; DATA XREF: ROM:0001226E   o  ; was: sub_122B8
                lea     Stage2ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage2Configuration
; Applies the configuration selected by the Stage 3 table entry
Stage_ApplyStage3Configuration:                         ; DATA XREF: ROM:00012270   o  ; was: sub_122C2
                lea     Stage3ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage3Configuration
; Applies the configuration selected by the Stage 4 table entry
Stage_ApplyStage4Configuration:                         ; DATA XREF: ROM:00012272   o  ; was: sub_122CC
                lea     Stage4ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage4Configuration
; Applies the configuration selected by the Stage 5 table entry
Stage_ApplyStage5Configuration:                         ; DATA XREF: ROM:00012274   o  ; was: sub_122D6
                lea     Stage5ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage5Configuration
; Applies the configuration selected by the Stage 6 table entry
Stage_ApplyStage6Configuration:                         ; DATA XREF: ROM:00012276   o  ; was: sub_122E0
                lea     Stage6ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage6Configuration
; Applies the configuration selected by the Stage 7 table entry
Stage_ApplyStage7Configuration:                         ; DATA XREF: ROM:00012278   o  ; was: sub_122EA
                lea     Stage7ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage7Configuration
; Initializes stage 8 data with special scroll buffer setup
Stage_InitializeStage8:                                 ; DATA XREF: ROM:0001227A   o  ; was: sub_122F4
                lea     Stage8ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                move.w  #$81E0,(LargeTilemapPage2).l
                lea     (PlaneTilemapRow9).l,a0
                lea     (PlaneTilemapRow10).l,a1
                lea     (PlaneTilemapRow24).l,a2
                moveq   #$C,d1
                moveq   #$3F,d7                         ; '?'
Stage8_FillThreeWordRanges:                             ; CODE XREF: Stage_InitializeStage8+2E   j  ; was: loc_1231C
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                dbf     d7,Stage8_FillThreeWordRanges
                move.b  #$82,(Stage8TilemapMode).l
                rts
; End of function Stage_InitializeStage8
; Initializes the Stage 9 configuration and shared word ranges
Stage_InitializeStage9:                                 ; DATA XREF: ROM:0001227C   o  ; was: sub_12330
                lea     Stage9ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
Stage_ClearPaletteHighBitsBeforeFourRangeFill:          ; CODE XREF: Stage_ApplyXiTigerConfiguration+A   j  ; was: loc_1233A
                jsr     (Boss_FlyingNeoClearPaletteHighBits).l
Stage_PrepareFourWordRangesWithD:                       ; CODE XREF: Stage9_InitializeFlyCorridor+86   j  ; was: loc_12340
                lea     (PlaneTilemapRow25).l,a0
                lea     (PlaneTilemapRow26).l,a1
                lea     (PlaneTilemapRow27).l,a2
                lea     (PlaneTilemapRow28).l,a3
                moveq   #$D,d1
                moveq   #$3F,d7                         ; '?'
Stage_WriteDToFourWordRanges:                           ; CODE XREF: Stage_InitializeStage9+34   j  ; was: loc_1235C
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                move.w  d1,(a3)+
                dbf     d7,Stage_WriteDToFourWordRanges
                move.b  #$82,(Stage9TilemapMode).l
                rts
; End of function Stage_InitializeStage9
; Initializes stage 10 data structure and palette
Stage_ApplyStage10Configuration:                        ; DATA XREF: ROM:0001227E   o  ; was: sub_12372
                lea     Stage10ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage10Configuration
; Applies the configuration selected by the Stage 11 table entry
Stage_ApplyStage11Configuration:                        ; DATA XREF: ROM:00012280   o  ; was: sub_1237C
                lea     Stage11ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage11Configuration
; Applies the configuration selected by the Stage 12 table entry
Stage_ApplyStage12Configuration:                        ; DATA XREF: ROM:00012282   o  ; was: sub_12386
                lea     Stage12ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage12Configuration
; Applies the configuration selected by StageTableIndex $18 for Stage 13
Stage_ApplyStage13Configuration:                        ; DATA XREF: ROM:00012284   o  ; was: sub_12390
                lea     Stage13ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage13Configuration
; Clears 224 bytes of shared state beginning at FF7800
Stage_ClearSharedStateBuffer:                           ; CODE XREF: Stage12_UpdateScrollToExitTiles+1A   p  ; was: sub_1239A
                                        ; Stage13_InitializeSnakeEncounter+1A   p
                lea     (TerrainCollisionBuffer).l,a0
                moveq   #0,d0
                moveq   #$37,d7                         ; '7'
Stage_ClearNextSharedStateBufferLong:                   ; CODE XREF: Stage_ClearSharedStateBuffer+C   j  ; was: loc_123A4
                move.l  d0,(a0)+
                dbf     d7,Stage_ClearNextSharedStateBufferLong
                rts
; End of function Stage_ClearSharedStateBuffer
; Applies the configuration selected by the Stage 14 table entry
Stage_ApplyStage14Configuration:                        ; DATA XREF: ROM:00012286   o  ; was: sub_123AC
                lea     Stage14ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage14Configuration
; Applies the configuration selected by the Stage 15 table entry
Stage_ApplyStage15Configuration:                        ; DATA XREF: ROM:00012288   o  ; was: sub_123B6
                lea     Stage15ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage15Configuration
; Initializes stage 16 data with camera bounds setup
Stage_InitializeStage16:                                ; DATA XREF: ROM:0001228A   o  ; was: sub_123C0
                lea     Stage16ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                move.w  #$620,(CameraXLowerBound).w
                move.w  #$6A0,(CameraXUpperBound).w
                bset    #6,(PlayerRestrictionFlags).w
                rts
; End of function Stage_InitializeStage16
; Initializes stage 17 boss with sprites
Stage_InitializeStage17Boss:                            ; DATA XREF: ROM:0001228C   o  ; was: sub_123DE
                move.w  #4,(StageProcessTableOffset).w
                lea     Stage17BossConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                lea     (PlaneTilemapRow24).l,a0
                lea     (PlaneTilemapRow25).l,a1
                lea     (PlaneTilemapRow26).l,a2
                lea     (PlaneTilemapRow27).l,a3
                move.w  #$2FF,d1
                moveq   #$3F,d7                         ; '?'
Stage17_Write02FFToFourWordRanges:                      ; CODE XREF: Stage_InitializeStage17Boss+36   j  ; was: loc_1240C
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                move.w  d1,(a3)+
                dbf     d7,Stage17_Write02FFToFourWordRanges
                move.b  #$82,(Stage17TilemapMode).l
                move.b  #4,(VDPReg11Shadow+1).w
                move.b  #3,(PlaneBScrollModeFlags).w
                clr.w   (CameraXLowerBound).w
                clr.w   (CameraXUpperBound).w
                move.w  #$A,(PalettePrimaryIndex).w
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                move.w  #$40,(RasterEffectIndex).w      ; '@'
                clr.w   (RasterEffectInitState).w
                movea.w #(VScrollPlaneBColumn4-M68K_RAM),a0
                moveq   #$FFFFFFF0,d0
                moveq   #$B,d7
Stage17_WriteMinus16ToStridedEntityWords:               ; CODE XREF: Stage_InitializeStage17Boss+78   j  ; was: loc_12452
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Stage17_WriteMinus16ToStridedEntityWords
                move.w  #$484,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
                lea     Stage17IndexedTilemapRowData(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$81,d0
                moveq   #3,d7
                jsr     (VDPQueue_SetCommandHighWord).l
                lea     Stage17TileAssetCommands(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_InitializeStage17Boss
; ---------------------------------------------------------------------------
Stage17TileAssetCommands:   dc.w    7                   ; field_0  ; was: stru_12488
                                        ; DATA XREF: Stage_InitializeStage17Boss+9E   o
                dc.l    Boss_Epsilon1TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Epsilon1MappingData2020         ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Stage17IndexedTilemapRowData:   dc.w    $4E00, $4000, $900, $292A, $2B2C, $2D2E, $2F30, $3132  ; was: word_1249A
                                        ; DATA XREF: Stage_InitializeStage17Boss+86   o

; Foreground graphics setup
Stage_InitializeStage18:                                ; DATA XREF: ROM:0001228E   o  ; was: sub_124AA
                lea     Stage18ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
Stage18And19_InitializeTilemapIndices:                  ; CODE XREF: Stage_InitializeStage19+10   j  ; was: loc_124B4
                movea.l #EndingStarYVelocities,a0
                move.w  #0,d0
                move.w  #$150,d1
                move.w  #$7F,d7
                jmp     Gfx_UpdateTilemapIndices
; End of function Stage_InitializeStage18
; Initializes the Stage 19 configuration and shared tilemap indices
Stage_InitializeStage19:                                ; DATA XREF: ROM:00012290   o  ; was: sub_124CC
                lea     Stage19ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                jsr     (Stage18And19_SharedReturn).l
                bra.s   Stage18And19_InitializeTilemapIndices
; End of function Stage_InitializeStage19
; Unreferenced wrapper for the first Stage 20 configuration variant
UnreferencedApplyStage20Variant1Configuration:
                lea     UnreferencedStage20Variant1ConfigRecord(pc),a0  ; was: sub_124DE
                nop
                bra.s   UnreferencedApplyStage20VariantAndFillWordRanges
; End of function UnreferencedApplyStage20Variant1Configuration
; Unreferenced wrapper for the second Stage 20 configuration variant
UnreferencedApplyStage20Variant2Configuration:
                lea     UnreferencedStage20Variant2ConfigRecord(pc),a0  ; was: sub_124E6
                nop
UnreferencedApplyStage20VariantAndFillWordRanges:       ; CODE XREF: UnreferencedApplyStage20Variant1Configuration+6   j  ; was: loc_124EC
                                        ; UnreferencedApplyStage20Variant3Configuration+6   j
                bsr.w   Stage_ApplyConfigurationRecord
                lea     (PlaneTilemapRow26).l,a0
                lea     (PlaneTilemapRow27).l,a1
                lea     (PlaneTilemapRow28).l,a2
                lea     (PlaneTilemapRow29).l,a3
                move.w  #$300,d1
                moveq   #$3F,d7                         ; '?'
UnreferencedStage20Write0300ToFourWordRanges:           ; CODE XREF: UnreferencedApplyStage20Variant2Configuration+30   j  ; was: loc_1250E
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                move.w  d1,(a3)+
                dbf     d7,UnreferencedStage20Write0300ToFourWordRanges
                move.b  #$82,(SevenForceTilemapMode).l
                rts
; End of function UnreferencedApplyStage20Variant2Configuration
; Unreferenced wrapper for the third Stage 20 configuration variant
UnreferencedApplyStage20Variant3Configuration:
                lea     UnreferencedStage20Variant3ConfigRecord(pc),a0  ; was: sub_12524
                nop
                bra.w   UnreferencedApplyStage20VariantAndFillWordRanges
; End of function UnreferencedApplyStage20Variant3Configuration
; Unreferenced wrapper for the fourth Stage 20 configuration variant
UnreferencedApplyStage20Variant4Configuration:
                lea     UnreferencedStage20Variant4ConfigRecord(pc),a0  ; was: sub_1252E
                nop
                bra.w   UnreferencedApplyStage20VariantAndFillWordRanges
; End of function UnreferencedApplyStage20Variant4Configuration
; Initializes the Stage 20 tilemap, configuration, and camera values
Stage_InitializeStage20:                                ; DATA XREF: ROM:00012292   o  ; was: sub_12538
                lea     (LargeTilemapBuffer).l,a0
                move.w  #$8000,d0
                move.w  #$180,d1
                move.w  #$BF,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                lea     Stage20ConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                move.w  #$180,(PlayerXPosition).w
                addi.w  #$20,(PrimaryCameraXPosition).w  ; ' '
                move.w  (PrimaryCameraXPosition).w,(PreviousCameraXPosition).w
                rts
; End of function Stage_InitializeStage20
; Initializes the Stage 21 configuration and flags
Stage_InitializeStage21:                                ; DATA XREF: ROM:00012294   o  ; was: sub_1256E
                bset    #7,(CameraMotionLockFlags).w
                bset    #6,(CameraMotionLockFlags).w
                lea     Stage21ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_InitializeStage21
; Initializes the Stage 22 configuration and flags
Stage_InitializeStage22:                                ; DATA XREF: ROM:00012296   o  ; was: sub_12584
                bset    #7,(CameraMotionLockFlags).w
                bset    #6,(CameraMotionLockFlags).w
                lea     Stage22ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_InitializeStage22
; Initializes the Stage 23 configuration and flags
Stage_InitializeStage23:                                ; DATA XREF: ROM:00012298   o  ; was: sub_1259A
                bset    #7,(CameraMotionLockFlags).w
                bset    #6,(CameraMotionLockFlags).w
                lea     Stage23ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_InitializeStage23
; Applies the configuration selected by the Stage 24 table entry
Stage_ApplyStage24Configuration:                        ; DATA XREF: ROM:0001229A   o  ; was: sub_125B0
                lea     Stage24ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage24Configuration
; Unreferenced flagged configuration wrapper A
UnreferencedApplyFlaggedConfigurationA:
                bset    #1,(PlayerModeFlags).w          ; was: sub_125BA
                lea     UnreferencedFlaggedConfigRecordA(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function UnreferencedApplyFlaggedConfigurationA
; Unreferenced flagged configuration wrapper B
UnreferencedApplyFlaggedConfigurationB:
                bset    #1,(PlayerModeFlags).w          ; was: sub_125CA
                lea     UnreferencedFlaggedConfigRecordB(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function UnreferencedApplyFlaggedConfigurationB
; Applies the configuration selected by the Stage 25 table entry
Stage_ApplyStage25Configuration:                        ; DATA XREF: ROM:0001229C   o  ; was: sub_125DA
                lea     Stage25ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage25Configuration
; Applies the configuration selected by the Stage 26 table entry
Stage_ApplyStage26Configuration:                        ; DATA XREF: ROM:0001229E   o  ; was: sub_125E4
                lea     Stage26ConfigRecord(pc),a0
                nop
                bra.w   Stage_ApplyConfigurationRecord
; End of function Stage_ApplyStage26Configuration
; Builds the Stage 3 phase-2 resampling steps, transforms its tiles, and uploads them
Gfx_PrepareStage21And22ResampledTiles:                  ; CODE XREF: Stage_LoadStage21And22Assets+12   p  ; was: sub_125EE
                movea.w #(Stage3ScaleStepTable-M68K_RAM),a0
                move.l  #$600000,d0
                move.w  #$2000,d1
                move.w  #$1A0,d3
                moveq   #$5F,d7                         ; '_'
Gfx_BuildStage21And22ScaleStepTable:                    ; CODE XREF: Gfx_PrepareStage21And22ResampledTiles+20   j  ; was: loc_12602
                move.l  d0,d2
                divu.w  d1,d2
                ext.l   d2
                asl.l   #8,d2
                move.l  d2,(a0)+
                add.w   d3,d1
                dbf     d7,Gfx_BuildStage21And22ScaleStepTable
                move.l  #Stage21And22PackedTileSource,(Stage3PackedTilePtr).w
                move.l  #Stage3ScaleStepTable,(Stage3ScaleTablePtr).w
                move.w  #$5F,(Stage3ResampleGroupsM1).w  ; '_'
                move.w  #3,(Stage3ResamplePassesM1).w
                bsr.w   Gfx_ResampleStage21And22Tiles
                movea.l #M68K_RAM,a0
                move.w  #$3C00,d5
                move.l  #$93009412,d4
                jmp     Gfx_DmaTransferWithZ80Halt
; End of function Gfx_PrepareStage21And22ResampledTiles
