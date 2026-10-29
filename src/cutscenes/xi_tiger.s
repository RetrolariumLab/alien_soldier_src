; Loads the Xi Tiger transition's object data, palettes, and frame-decompression state
XiTigerCutscene_LoadAssets:                             ; was: sub_1E86A
                                        ; StageTransition_DispatchUpdate+8   o
                lea     XiTigerCutscene_AssetLoadDescriptors(pc),a0
                nop
                jsr     (LoadObjData).l
                lea     (XiTigerCutscenePaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.w  (PlayerHealth).w,(DisplayedPlayerHealth).w
                move.w  #$7000,d0
                move.w  d0,(DisplayedBossHealth).w
                move.w  d0,(BossHealth).w
                move.w  d0,(BossMaxHealth).w
                bset    #0,(StageTimerPauseFlag).w
                jmp     CutsceneProjection_Initialize
; End of function XiTigerCutscene_LoadAssets
; ---------------------------------------------------------------------------
; Each entry is a LoadObjData type, source pointer, and destination word
; Type 7 writes decompressed bytes to VRAM; type 6 writes them to RAM
XiTigerCutscene_AssetLoadDescriptors:   dc.w    7       ; type 7; was: stru_1E8A4
                dc.l    XiTigerCutsceneTileArt          ; compressed source
                dc.w    $6000                           ; VRAM destination
                dc.w    6                               ; type 6; tilemap words
                dc.l    XiTigerCutsceneTilemapWordSource  ; 676 decoded words
                dc.w    $4000                           ; RAM destination $FFFF4000
                dc.w    6                               ; type 6; block indices
                dc.l    XiTigerCutsceneTilemapBlockIndices  ; 64 decoded bytes
                dc.w    $6000                           ; RAM destination $FFFF6000
                dc.w    3                               ; field_0
                dc.l    XiTigerCutsceneType3Data0000    ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    XiTigerCutsceneMappingData2020  ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    XiTigerCutsceneMappingData6800  ; field_2
                dc.w    $6800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedGameplayTileArtD000       ; field_2
                dc.w    $D000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    XiTigerCutsceneTileArt7800      ; field_2
                dc.w    $7800                           ; field_6
                dc.w    $FFFF

; Updates the HUD and dispatches the current Xi Tiger cutscene state
XiTigerCutscene_Update:                                 ; was: sub_1E8F6
                jsr     (UI_BuildHUDSpriteList).l
                jsr     (UI_UpdateGameplayHUD).l
                move.w  (XiTigerStateOffset).w,d0
                movea.w XiTigerCutscene_StateTable(pc,d0.w),a0
                adda.l  #XiTigerCutscene_Setup,a0
                jmp     (a0)
; End of function XiTigerCutscene_Update
; ---------------------------------------------------------------------------
XiTigerCutscene_StateTable: dc.w    XiTigerCutscene_Setup-XiTigerCutscene_Setup  ; was: off_1E912
                dc.w    XiTigerCutscene_WaitBeforeReveal-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_AdvanceReveal-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_InitializeReveal-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_AnimateReveal-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_UpdateRevealOffsets-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_AnimateFlash-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_AnimateFadeOut-XiTigerCutscene_Setup
                dc.w    XiTigerCutscene_EnterStageHandler-XiTigerCutscene_Setup

; Sets up Xi Tiger cutscene
XiTigerCutscene_Setup:                                  ; was: sub_1E924
                                        ; ROM:XiTigerCutscene_StateTable   o
                addq.w  #2,(XiTigerStateOffset).w
                move.l  #$20000,(XiTigerMotionStep).w
                move.w  #$100,(XiTigerStateCounter).w
                move.b  #$1E,d0
                jsr     (Sound_QueueSFXRequest).l
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                bsr.w   XiTigerCutscene_InitializeDisplayObject
                lea     $60(a0),a0
                bsr.w   XiTigerCutscene_InitializeDisplayObject
                bset    #3,$E(a0)
                move.w  #0,(PrimaryCameraXPosition).w
                move.w  #$28,(SecondaryCameraXPos).w    ; '('
                lea     XiTigerCutscene_TileTransferDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedColumns).l
                lea     XiTigerCutscene_IndexedRowTransferDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function XiTigerCutscene_Setup
; ---------------------------------------------------------------------------
XiTigerCutscene_TileTransferDescriptor:         dc.l    $44214000, $1020203, $B0C090A  ; was: dword_1E97A
XiTigerCutscene_IndexedRowTransferDescriptor:   dc.l    $68204000, $4010405, $607080D, $E0F1011  ; was: dword_1E986

; Initializes Xi-Tiger cutscene with graphics
XiTigerCutscene_InitializeDisplayObject:                ; was: sub_1E996
                                        ; XiTigerCutscene_Setup+28   p
                move.w  #$10,(a0)
                move.w  #$CC00,2(a0)
                move.w  #$E3C0,$E(a0)
                move.l  #XiTigerCutscene_DisplayObjectSpriteMapping,8(a0)
XiTigerCutscene_Return:                                 ; was: locret_1E9AE
                                        ; XiTigerCutscene_SpawnMarker+6   j
                rts
; End of function XiTigerCutscene_InitializeDisplayObject
; Advances the initial reveal source and palette phase
XiTigerCutscene_AdvanceReveal:                          ; was: sub_1E9B0
                subi.l  #$1800,(CutsceneScaleStep).w
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   XiTigerCutscene_UpdateRevealFrame
                addq.w  #2,(XiTigerPaletteLevel).w
                cmpi.w  #$E,(XiTigerPaletteLevel).w
                bmi.s   XiTigerCutscene_UpdateRevealFrame
                addq.w  #2,(XiTigerStateOffset).w
XiTigerCutscene_UpdateRevealFrame:                      ; was: loc_1E9D2
                                        ; XiTigerCutscene_AdvanceReveal+1C   j
                bsr.w   XiTigerCutscene_ApplyPaletteFade
                bra.s   XiTigerCutscene_RenderWaitingFrame
; End of function XiTigerCutscene_AdvanceReveal
; Holds the opening composition while emitting particles, then begins the reveal
XiTigerCutscene_WaitBeforeReveal:                       ; was: sub_1E9D8
                subq.w  #1,(XiTigerStateCounter).w
                bpl.s   XiTigerCutscene_UpdateWaitingFrame
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,(XiTigerStateOffset).w
                move.w  #$50,(XiTigerStateCounter).w    ; 'P'
                clr.w   (Entity_ObjectPool).w
                clr.w   (SecondaryEntityType).w
XiTigerCutscene_UpdateWaitingFrame:                     ; was: loc_1E9FA
                bsr.w   XiTigerCutscene_SpawnRandomParticle
                move.w  (XiTigerPhaseCounter).w,d0
                cmpi.w  #$200,d0
                bmi.s   XiTigerCutscene_RenderWaitingFrame
                andi.w  #$F,d0
                bne.s   XiTigerCutscene_RenderWaitingFrame
                moveq   #$E,d7
                bsr.w   XiTigerCutscene_SpawnMarkerPair
XiTigerCutscene_RenderWaitingFrame:                     ; was: loc_1EA14
                                        ; XiTigerCutscene_WaitBeforeReveal+2E   j
                bsr.w   XiTigerCutscene_UpdateActorAndLayerPositions
                bsr.w   XiTigerCutscene_BuildCompositeSprite
                jmp     CutsceneProjection_BuildFrame
; End of function XiTigerCutscene_WaitBeforeReveal
; Initializes the scrolling reveal and its raster-effect state
XiTigerCutscene_InitializeReveal:                       ; was: sub_1EA22
                subq.w  #1,(XiTigerStateCounter).w
                bpl.w   XiTigerCutscene_Return
                move.b  #$82,d0
                jsr     (Sound_QueueBGMRequest).l
                addq.w  #2,(XiTigerStateOffset).w
                clr.w   (PaletteShadowColor29).w
                clr.w   (PaletteShadowColor30).w
                clr.w   (XiTigerPhaseCounter).w
                move.l  #$1820000,(XiTigerMotionStep).w
                clr.w   (XiTigerStateCounter).w
                move.w  #$FFE0,(XiTigerSpriteXOffset).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #7,(VDPReg11Shadow+1).w
                move.b  #6,(PlaneAScrollModeFlags).w
                move.b  #9,(PlaneBScrollModeFlags).w
                move.w  #0,(PrimaryCameraXPosition).w
                move.w  #0,(PrimaryCameraYPosition).w
                move.w  #0,(SecondaryCameraXPos).w
                move.w  #0,(SecondaryCameraYPos).w
                jsr     (Tilemap_DirectTransferFromPrimaryCamera).l
                move.w  #$1E0,(PrimaryCameraXPosition).w
                jmp     Tilemap_DirectTransferFromSecondaryCamera
; End of function XiTigerCutscene_InitializeReveal
; Animates the reveal's palette phase, offsets, and composition
XiTigerCutscene_AnimateReveal:                          ; was: sub_1EA9A
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   XiTigerCutscene_UpdateRevealOffsets
                subq.w  #2,(XiTigerPaletteLevel).w
                bne.s   XiTigerCutscene_UpdateRevealOffsets
                addq.w  #2,(XiTigerStateOffset).w
; Updates the reveal offsets on alternating frames; this path does not read input
XiTigerCutscene_UpdateRevealOffsets:                    ; was: loc_1EAAE
                                        ; XiTigerCutscene_AnimateReveal+E   j
                btst    #0,(FrameCounter+1).w
                bne.s   XiTigerCutscene_AdvanceRevealTimer
                addq.w  #1,(XiTigerSpriteXOffset).w
                bmi.s   XiTigerCutscene_AdvanceRevealTimer
                clr.w   (XiTigerSpriteXOffset).w
XiTigerCutscene_AdvanceRevealTimer:                     ; was: loc_1EAC0
                                        ; XiTigerCutscene_UpdateRevealOffsets+C   j
                addq.w  #1,(XiTigerPhaseCounter).w
                cmpi.w  #$C0,(XiTigerPhaseCounter).w
                bne.s   XiTigerCutscene_ContinueReveal
                move.b  #$11,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,(XiTigerStateOffset).w
                move.w  #$48,(PaletteShadowColor29).w   ; 'H'
                move.w  #$2AE,(PaletteShadowColor30).w
                move.w  #$C,(XiTigerPaletteLevel).w
                bra.s   XiTigerCutscene_AnimateFlash
; ---------------------------------------------------------------------------
XiTigerCutscene_ContinueReveal:                         ; was: loc_1EAEE
                bsr.w   XiTigerCutscene_UpdateWaveAndLayerPositions
                bsr.w   XiTigerCutscene_ApplyPaletteFade
                bra.w   XiTigerCutscene_BuildCompositeSprite
; End of function XiTigerCutscene_AnimateReveal
; Animates the timed palette flash before fade-out
XiTigerCutscene_AnimateFlash:                           ; was: sub_1EAFA
                addq.w  #1,(XiTigerPhaseCounter).w
                cmpi.w  #$160,(XiTigerPhaseCounter).w
                bne.s   XiTigerCutscene_UpdateFlash
                addq.w  #2,(XiTigerStateOffset).w
                bra.s   XiTigerCutscene_AnimateFadeOut
; ---------------------------------------------------------------------------
XiTigerCutscene_UpdateFlash:                            ; was: loc_1EB0C
                subq.w  #1,(XiTigerPaletteLevel).w
                bpl.s   XiTigerCutscene_ApplyFlashPalette
                clr.w   (XiTigerPaletteLevel).w
XiTigerCutscene_ApplyFlashPalette:                      ; was: loc_1EB16
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                move.w  #$8000,d7
                moveq   #$E,d5
                bsr.w   XiTigerCutscene_ApplySelectedPaletteFade
                bsr.w   XiTigerCutscene_UpdateWaveAndLayerPositions
                bra.w   XiTigerCutscene_BuildCompositeSprite
; End of function XiTigerCutscene_AnimateFlash
; Reduces the reveal offset and palette intensity before leaving the cutscene
XiTigerCutscene_AnimateFadeOut:                         ; was: sub_1EB2C
                subq.w  #2,(XiTigerSpriteXOffset).w
                addq.w  #1,(XiTigerPaletteLevel).w
                cmpi.w  #$10,(XiTigerPaletteLevel).w
                bne.s   XiTigerCutscene_UpdateFadeOut
                addq.w  #2,(XiTigerStateOffset).w
                rts
; ---------------------------------------------------------------------------
XiTigerCutscene_UpdateFadeOut:                          ; was: loc_1EB42
                bsr.w   XiTigerCutscene_UpdateWaveAndLayerPositions
                bsr.w   XiTigerCutscene_BuildCompositeSprite
                bra.w   XiTigerCutscene_ApplyPaletteFade
; End of function XiTigerCutscene_AnimateFadeOut
; Leaves the transition cutscene for the Xi Tiger stage handler
XiTigerCutscene_EnterStageHandler:                      ; was: sub_1EB4E
                jsr     (Stage_LoadAssetsForCurrentTableIndex).l
                move.w  #$80,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                move.w  #0,(XiTigerConfigIndex).w
                rts
; End of function XiTigerCutscene_EnterStageHandler
; Builds three ten-entry strips for the cutscene's composite sprite
XiTigerCutscene_BuildCompositeSprite:                   ; was: sub_1EB66
                                        ; XiTigerCutscene_AnimateReveal+5C   j
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                move.w  #$C3DC,d0
                move.w  #$F00,d1
                move.w  #$A0,d3
                add.w   (XiTigerSpriteXOffset).w,d3
                bsr.s   XiTigerCutscene_WriteCompositeStrip
                move.w  #$140,d3
                add.w   (XiTigerSpriteXOffset).w,d3
                bsr.s   XiTigerCutscene_WriteCompositeStrip
                move.w  #$160,d3
                add.w   (XiTigerSpriteXOffset).w,d3
                bsr.s   XiTigerCutscene_WriteCompositeStrip
                move.w  #$FFFF,(a0)
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function XiTigerCutscene_BuildCompositeSprite
; Writes one ten-entry strip into the OAM staging list
XiTigerCutscene_WriteCompositeStrip:                    ; was: sub_1EB9E
                                        ; XiTigerCutscene_BuildCompositeSprite+1E   p
                move.w  #$80,d2
                moveq   #9,d7
XiTigerCutscene_WriteNextStripEntry:                    ; was: loc_1EBA4
                move.w  d3,(a0)+
                move.w  d1,(a0)+
                move.w  d0,(a0)+
                move.w  d2,(a0)+
                addi.w  #$20,d2                         ; ' '
                dbf     d7,XiTigerCutscene_WriteNextStripEntry
                rts
; End of function XiTigerCutscene_WriteCompositeStrip
; Updates the paired display objects and layer offsets from the phase accumulator
XiTigerCutscene_UpdateActorAndLayerPositions:           ; was: sub_1EBB6
                addi.l  #$800,(XiTigerMotionStep).w
                move.w  (XiTigerMotionStep).w,d0
                add.w   d0,(XiTigerPhaseCounter).w
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                movea.w #(SecondaryEntityType-M68K_RAM),a1
                move.w  (XiTigerPhaseCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                cmpi.w  #$20,d0                         ; ' '
                bmi.s   XiTigerCutscene_ApplyActorPositions
                subi.w  #$20,d0                         ; ' '
                eori.w  #$1F,d0
XiTigerCutscene_ApplyActorPositions:                    ; was: loc_1EBE4
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
                addi.w  #$133,d0
                move.w  d0,$14(a0)
                move.w  d0,$14(a1)
                asr.w   #1,d2
                move.w  #$14E,d0
                add.w   d2,d0
                move.w  d0,$10(a0)
                move.w  #$F2,d0
                sub.w   d2,d0
                move.w  d0,$10(a1)
                asr.w   #1,d1
                addq.w  #1,d1
                move.w  d1,(SecondaryCameraYPos).w
                asr.w   #1,d1
                subi.w  #$18,d1
                move.w  d1,(CutsceneVerticalOffset).w
                rts
; End of function XiTigerCutscene_UpdateActorAndLayerPositions
; Applies the main palette fade to all 64 cutscene colors
XiTigerCutscene_ApplyPaletteFade:                       ; was: sub_1EC20
                                        ; XiTigerCutscene_AnimateReveal+58   p
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                move.w  #$E000,d7
                moveq   #$3F,d5                         ; '?'
XiTigerCutscene_ApplySelectedPaletteFade:               ; was: loc_1EC2A
                move.w  (XiTigerPaletteLevel).w,d0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function XiTigerCutscene_ApplyPaletteFade
; Writes the sine-wave raster table and updates the cutscene layer positions
XiTigerCutscene_UpdateWaveAndLayerPositions:            ; was: sub_1EC34
                                        ; XiTigerCutscene_AnimateFlash+2A   p
                movea.w #(HScrollPlaneBRow0-M68K_RAM),a0
                lea     (Math_QuarterSineTable).l,a1
                moveq   #0,d0
                addi.w  #$108,(XiTigerWavePhase).w
                move.w  (XiTigerWavePhase).w,d0
                move.l  #$1814000,d3
                move.w  #$DF,d7
XiTigerCutscene_WriteNextWaveLine:                      ; was: loc_1EC54
                move.w  d0,d2
                andi.w  #$1FE,d2
                move.w  (a1,d2.w),d1
                ext.l   d1
                asl.l   #8,d1
                swap    d1
                move.w  d1,(a0)
                swap    d0
                add.l   d3,d0
                swap    d0
                addq.w  #4,a0
                dbf     d7,XiTigerCutscene_WriteNextWaveLine
                subq.w  #4,(SecondaryCameraYPos).w
                move.w  (XiTigerSpriteXOffset).w,d7
                asr.w   #1,d7
                addq.w  #1,(XiTigerStateCounter).w
                move.w  (XiTigerStateCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                btst    #6,(XiTigerStateCounter+1).w
                beq.s   XiTigerCutscene_UpdateLayerPositions
                eori.w  #$3F,d0                         ; '?'
                btst    #0,(FrameCounter+1).w
                bne.s   XiTigerCutscene_UpdateLayerPositions
                addq.w  #1,(XiTigerStateCounter).w
XiTigerCutscene_UpdateLayerPositions:                   ; was: loc_1ECA0
                                        ; XiTigerCutscene_UpdateWaveAndLayerPositions+66   j
                subi.w  #$20,d0                         ; ' '
                ext.l   d0
                asl.l   #8,d0
                asl.l   #5,d0
                move.l  #$FFF80000,d1
                sub.l   d0,d1
                move.l  d1,d2
                swap    d2
                sub.w   d7,d2
                move.w  d2,(VScrollPlaneAColumn6).w
                move.w  d2,(VScrollPlaneAColumn13).w
                sub.l   d0,d1
                swap    d1
                sub.w   d7,d1
                move.w  d1,(VScrollPlaneAColumn5).w
                move.w  d1,(VScrollPlaneAColumn4).w
                move.w  d1,(VScrollPlaneAColumn3).w
                move.w  d1,(VScrollPlaneAColumn2).w
                move.w  d1,(VScrollPlaneAColumn14).w
                move.w  d1,(VScrollPlaneAColumn15).w
                move.w  d1,(VScrollPlaneAColumn16).w
                move.w  d1,(VScrollPlaneAColumn17).w
                moveq   #$FFFFFFF6,d1
                sub.w   d7,d1
                move.w  d1,(VScrollPlaneAColumn7).w
                move.w  d1,(VScrollPlaneAColumn12).w
                moveq   #$FFFFFFF4,d1
                swap    d0
                add.w   d0,d1
                sub.w   d7,d1
                move.w  d1,(VScrollPlaneAColumn8).w
                move.w  d1,(VScrollPlaneAColumn9).w
                move.w  d1,(VScrollPlaneAColumn10).w
                move.w  d1,(VScrollPlaneAColumn11).w
                move.w  (FrameCounter).w,d0
                andi.w  #2,d0
                asl.w   #2,d0
                move.w  XiTigerCutscene_AlternatingPaletteFrames(pc,d0.w),(PaletteActiveColor19).w
                move.w  XiTigerCutscene_AlternatingPaletteFrames+2(pc,d0.w),(PaletteActiveColor20).w
                move.w  XiTigerCutscene_AlternatingPaletteFrames+4(pc,d0.w),(PaletteActiveColor18).w
                rts
; End of function XiTigerCutscene_UpdateWaveAndLayerPositions
; ---------------------------------------------------------------------------
XiTigerCutscene_AlternatingPaletteFrames:   dc.w    $26, $68C, 2, 0  ; was: word_1ED28
                                        ; XiTigerCutscene_UpdateWaveAndLayerPositions+E6   r
                dc.w    $48, $248, 4, 0

; Spawns the two marker sprites at symmetric horizontal offsets
XiTigerCutscene_SpawnMarkerPair:                        ; was: sub_1ED38
                bsr.s   XiTigerCutscene_SpawnMarker
                neg.w   d7
; Spawns one animated marker sprite at X = $120 + d7
XiTigerCutscene_SpawnMarker:                            ; was: sub_1ED3C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   XiTigerCutscene_Return
                move.w  #$120,$10(a0)
                add.w   d7,$10(a0)
                lea     (XiTigerCutscene_MarkerSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.w  #$274,(a0)
                rts
; End of function XiTigerCutscene_SpawnMarker
; Anchors a marker to the scrolling vertical offset and advances its animation
XiTigerCutscene_UpdateMarker:                           ; was: sub_1ED62
                move.w  #$E1,d0
                sub.w   (CutsceneVerticalOffset).w,d0
                move.w  d0,$14(a5)
                jsr     (Anim_UpdateSpriteFrame).l
                bset    #7,$E(a5)
                rts
; End of function XiTigerCutscene_UpdateMarker
; Spawns one randomly positioned particle used during the opening hold
XiTigerCutscene_SpawnRandomParticle:                    ; was: sub_1ED7C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   XiTigerCutscene_Return
                move.b  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                addi.w  #$A0,d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$100,d0
                move.w  d0,$14(a0)
                lea     (Effect_SharedBurstParticleSpriteFrames).l,a1
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                addq.w  #8,d0
                neg.w   d0
                move.w  d0,$1C(a0)
                jmp     Sprite_InitFromTable
; End of function XiTigerCutscene_SpawnRandomParticle
