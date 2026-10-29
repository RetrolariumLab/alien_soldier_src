ShipSequence_Controller:                                ; was: sub_86F0
                cmpi.w  #$16,(ShipSequenceState).l
                bcc.s   ShipSequence_DispatchObjectState
                bsr.s   ShipSequence_AnimateArrivalPalette
ShipSequence_DispatchObjectState:                       ; was: loc_86FC
                move.w  4(a5),d0
                lea     ShipSequence_ObjectStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function ShipSequence_Controller
; ---------------------------------------------------------------------------
ShipSequence_ObjectStates:  dc.w    ShipSequence_InitializeTimeline-*  ; was: off_8708
                dc.w    ShipSequence_Update-*

; Alternates the arrival palette between its shadow colors and a bright frame
ShipSequence_AnimateArrivalPalette:                     ; was: sub_870C
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                btst    #0,(FrameCounter+1).w
                bne.s   ShipSequence_ApplyBrightArrivalPalette
                movea.w #(PaletteShadowBuffer-M68K_RAM),a1
                move.w  $64(a1),$64(a0)
                move.w  $66(a1),$66(a0)
                move.w  $68(a1),$68(a0)
                move.w  $6A(a1),$6A(a0)
                move.w  $6C(a1),$6C(a0)
                move.w  $6E(a1),$6E(a0)
                move.w  $74(a1),$74(a0)
                move.w  $76(a1),$76(a0)
                move.w  $78(a1),$78(a0)
                move.w  $7A(a1),$7A(a0)
                move.w  $7C(a1),$7C(a0)
                rts
; ---------------------------------------------------------------------------
ShipSequence_ApplyBrightArrivalPalette:                 ; was: loc_8760
                moveq   #$20,d0                         ; ' '
                move.w  #$CEE,$64(a0)
                move.w  #$2E,$66(a0)                    ; '.'
                move.w  #$CE,$68(a0)
                move.w  #$482,$6A(a0)
                move.w  #$AE8,$6C(a0)
                move.w  #$EEC,$6E(a0)
                add.w   d0,$74(a0)
                add.w   d0,$76(a0)
                add.w   d0,$78(a0)
                add.w   d0,$7A(a0)
                add.w   d0,$7C(a0)
                rts
; End of function ShipSequence_AnimateArrivalPalette
; Initializes both timed spawn-script cursors and the sequence clocks
ShipSequence_InitializeTimeline:                        ; was: sub_879C
                move.l  #ShipPiece_SpawnScript,(ShipPieceScriptCursor).l
                move.l  #ShipDebris_SpawnScript,(ShipDebrisCursor).l
                clr.w   (ShipSequenceFrame).l
                clr.w   (ShipSequenceState).l
                addq.w  #2,4(a5)
                rts
; End of function ShipSequence_InitializeTimeline
; Runs timed piece/debris spawning, the scene timeline, and final cleanup
ShipSequence_Update:                                    ; was: sub_87C2
                addq.w  #1,(ShipSequenceFrame).l
                bsr.w   ShipSequence_SpawnScheduledPiece
                bsr.w   ShipSequence_SpawnScheduledDebris
                bsr.w   ShipSequence_UpdateStateAndScroll
                cmpi.w  #$6C0,(ShipSequenceFrame).l
                bmi.s   ShipSequence_UpdateReturn
                bclr    #0,(SceneSequenceFlags).w
                moveq   #0,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
ShipSequence_UpdateReturn:                              ; was: locret_87EE
                rts
; End of function ShipSequence_Update
; Advances the current timeline state and then integrates vertical scrolling
ShipSequence_UpdateStateAndScroll:                      ; was: sub_87F0
                bsr.w   ShipSequence_DispatchTimelineState
                bra.w   ShipSequence_UpdateVerticalScroll
; End of function ShipSequence_UpdateStateAndScroll
; Dispatches the sixteen-state ship and pattern-reveal timeline
ShipSequence_DispatchTimelineState:                     ; was: sub_87F8
                move.w  (ShipSequenceState).l,d0
                lea     ShipSequence_TimelineStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function ShipSequence_DispatchTimelineState
; ---------------------------------------------------------------------------
ShipSequence_TimelineStates:    dc.w    ShipSequence_WaitForNameAndArrival-*  ; was: off_8806
                dc.w    ShipSequence_LoadTileBatch1-*
                dc.w    ShipSequence_LoadTileBatch2-*
                dc.w    ShipSequence_LoadTileBatch3-*
                dc.w    ShipSequence_LoadTileBatch4-*
                dc.w    ShipSequence_LoadTileBatch5-*
                dc.w    ShipSequence_WaitForTileBatches-*
                dc.w    ShipSequence_DecelerateVerticalScroll-*
                dc.w    ShipSequence_AccelerateVerticalScroll-*
                dc.w    ShipSequence_WaitForVerticalPosition-*
                dc.w    ShipSequence_FlashAndClearObjects-*
                dc.w    ShipSequence_InitializePatternReveal-*
                dc.w    ShipSequence_RevealPattern-*
                dc.w    ShipSequence_WaitForBackgroundLoad-*
                dc.w    ShipSequence_FadeOutPattern-*
                dc.w    ShipSequence_Complete-*

; Shows the ship name at frame `$40`, then starts the arrival at frame `$200`
ShipSequence_WaitForNameAndArrival:                     ; was: sub_8826
                cmpi.w  #$40,(ShipSequenceFrame).l      ; '@'
                beq.s   ShipSequence_ShowName
                cmpi.w  #$200,(ShipSequenceFrame).l
                bcs.w   Cutscene_Return
                move.b  #1,(PlaneAScrollModeFlags).w
                move.l  #$FFC00000,(ShipVerticalPosition).l
                clr.l   (ShipVerticalVelocity).l
                addq.w  #2,(ShipSequenceState).l
                move.b  #$D5,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function ShipSequence_WaitForNameAndArrival
; Starts ship-name script zero in the shared message-sequence engine
ShipSequence_ShowName:                                  ; was: sub_8864
                move.w  #0,d0
                jsr     (ShipName_StartScript).l
                rts
; End of function ShipSequence_ShowName
; Loads the first arrival tile batch and starts upward scrolling at -1 pixel/frame
ShipSequence_LoadTileBatch1:                            ; was: sub_8870
                movea.l #ShipSequence_TileBatch1,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$20,(ShipTileLoadTimer).l      ; ' '
                move.w  #$FFFF,(ShipVerticalVelocity).l
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_LoadTileBatch1
; Loads the second arrival tile batch after a `$20`-frame delay
ShipSequence_LoadTileBatch2:                            ; was: sub_8894
                subq.w  #1,(ShipTileLoadTimer).l
                bne.w   Cutscene_Return
                movea.l #ShipSequence_TileBatch2,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$20,(ShipTileLoadTimer).l      ; ' '
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_LoadTileBatch2
; Loads the third arrival tile batch after a `$20`-frame delay
ShipSequence_LoadTileBatch3:                            ; was: sub_88BA
                subq.w  #1,(ShipTileLoadTimer).l
                bne.w   Cutscene_Return
                movea.l #ShipSequence_TileBatch3,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$20,(ShipTileLoadTimer).l      ; ' '
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_LoadTileBatch3
; Loads the fourth arrival tile batch after a `$20`-frame delay
ShipSequence_LoadTileBatch4:                            ; was: sub_88E0
                subq.w  #1,(ShipTileLoadTimer).l
                bne.w   Cutscene_Return
                movea.l #ShipSequence_TileBatch4,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$20,(ShipTileLoadTimer).l      ; ' '
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_LoadTileBatch4
; Loads the fifth arrival tile batch after a `$20`-frame delay
ShipSequence_LoadTileBatch5:                            ; was: sub_8906
                subq.w  #1,(ShipTileLoadTimer).l
                bne.w   Cutscene_Return
                movea.l #ShipSequence_TileBatch5,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$20,(ShipTileLoadTimer).l      ; ' '
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_LoadTileBatch5
; Holds the fifth arrival tile batch for its final `$20`-frame delay
ShipSequence_WaitForTileBatches:                        ; was: sub_892C
                subq.w  #1,(ShipTileLoadTimer).l
                bne.w   Cutscene_Return
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_WaitForTileBatches
; Raises the signed 16.16 vertical velocity from -1 to zero, then enables priority
ShipSequence_DecelerateVerticalScroll:                  ; was: sub_893E
                addi.l  #$10000,(ShipVerticalVelocity).l
                tst.w   (ShipVerticalVelocity).l
                bmi.w   Cutscene_Return
                bsr.w   ShipSequence_EnableArrivalPlanePriority
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_DecelerateVerticalScroll
; Accelerates the vertical scroll velocity from zero to `$00008000`
ShipSequence_AccelerateVerticalScroll:                  ; was: sub_895E
                addi.l  #$2000,(ShipVerticalVelocity).l
                cmpi.l  #$8000,(ShipVerticalVelocity).l
                bcs.w   Cutscene_Return
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_AccelerateVerticalScroll
; Waits for vertical position `$FF20`, restarts the name script, and arms flashing
ShipSequence_WaitForVerticalPosition:                   ; was: sub_897E
                cmpi.w  #$FF20,(ShipVerticalPosition).l
                bcs.w   Cutscene_Return
                move.w  #0,d0
                jsr     (ShipName_StartScript).l
                clr.w   (ShipFlashState).l
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_WaitForVerticalPosition
; Runs the ship flash until frame `$588`, then clears 46 arrival objects
ShipSequence_FlashAndClearObjects:                      ; was: sub_89A2
                bsr.w   ShipSequence_DispatchFlashState
                eori.w  #$8000,(TertiaryEntityAttr).w
                cmpi.w  #$588,(ShipSequenceFrame).l
                bcs.w   Cutscene_Return
                bsr.w   ShipSequence_DisableArrivalPlanePriority
                lea     (TertiaryEntityFlags).w,a0
                move.w  #$2D,d0                         ; '-'
ShipSequence_ClearNextObject:                           ; was: loc_89C4
                move.w  #$1000,(a0)
                adda.w  #$60,a0                         ; '`'
                dbf     d0,ShipSequence_ClearNextObject
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_FlashAndClearObjects
; Dispatches the three-state arrival flash loop
ShipSequence_DispatchFlashState:                        ; was: sub_89D8
                move.w  (ShipFlashState).l,d0
                lea     ShipSequence_FlashStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function ShipSequence_DispatchFlashState
; ---------------------------------------------------------------------------
ShipSequence_FlashStates:   dc.w    ShipSequence_StartFlash-*  ; was: off_89E6
                dc.w    ShipSequence_UpdateFlash-*
                dc.w    ShipSequence_RestartFlash-*

; Starts one flash cycle with velocity `$4000`, a `$40`-frame timer, and SFX `$D8`
ShipSequence_StartFlash:                                ; was: sub_89EC
                move.l  #$4000,(ShipVerticalVelocity).l
                move.w  #$40,(ShipFlashTimer).l         ; '@'
                move.w  #2,(ShipFlashState).l
                move.b  #$D8,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function ShipSequence_StartFlash
; Toggles the first H-scroll word while advancing the flash timer and position
ShipSequence_UpdateFlash:                               ; was: sub_8A12
                bsr.w   ShipSequence_StepFlashPosition
                eori.w  #2,(HScrollBuffer).w
                subq.w  #1,(ShipFlashTimer).l
                bne.w   Cutscene_Return
                move.l  #$FFFFC000,(ShipVerticalVelocity).l
                move.w  #$60,(ShipFlashTimer).l         ; '`'
                addq.w  #2,(ShipFlashState).l
                rts
; End of function ShipSequence_UpdateFlash
; Moves the vertical position four pixels every `$20` flash ticks
ShipSequence_StepFlashPosition:                         ; was: sub_8A40
                move.w  (ShipFlashTimer).l,d0
                andi.w  #$1F,d0
                bne.w   Cutscene_Return
                addi.w  #4,(ShipVerticalPosition).l
                rts
; End of function ShipSequence_StepFlashPosition
; Restarts the flash cycle after its `$60`-frame second phase
ShipSequence_RestartFlash:                              ; was: sub_8A58
                subq.w  #1,(ShipFlashTimer).l
                bne.w   Cutscene_Return
                bra.w   ShipSequence_StartFlash
; End of function ShipSequence_RestartFlash
; Unreferenced three-state vertical-jitter experiment retained from the ROM
OrphanedShipJitter_Dispatch:
                move.w  (ShipJitterState).l,d0          ; was: sub_8A66
                lea     OrphanedShipJitter_States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function OrphanedShipJitter_Dispatch
; ---------------------------------------------------------------------------
OrphanedShipJitter_States:  dc.w    OrphanedShipJitter_Start-*  ; was: off_8A74
                dc.w    OrphanedShipJitter_StartDelay-*
                dc.w    OrphanedShipJitter_Update-*

; Seeds the orphaned jitter timer and advances to its delay state
OrphanedShipJitter_Start:                               ; was: sub_8A7A
                move.w  #1,(ShipJitterTimer).l
                addq.w  #2,(ShipJitterState).l
                rts
; End of function OrphanedShipJitter_Start
; Waits one tick, loads a `$20`-frame jitter interval, and advances state
OrphanedShipJitter_StartDelay:                          ; was: sub_8A8A
                subq.w  #1,(ShipJitterTimer).l
                bne.w   Cutscene_Return
                move.w  #$20,(ShipJitterTimer).l        ; ' '
                addq.w  #2,(ShipJitterState).l
                rts
; End of function OrphanedShipJitter_StartDelay
; Alternates a shared scroll word and offsets vertical position by one pixel
OrphanedShipJitter_Update:                              ; was: sub_8AA4
                eori.w  #2,(PrimaryCameraXPosition).w
                tst.w   (PrimaryCameraXPosition).w
                bne.s   OrphanedShipJitter_IncrementPosition
                subi.w  #1,(ShipVerticalPosition).l
                bra.s   OrphanedShipJitter_Tick
; End of function OrphanedShipJitter_Update
; Applies the positive half of the jitter and advances its repeating timer
OrphanedShipJitter_IncrementPosition:                   ; was: sub_8ABA
                addi.w  #1,(ShipVerticalPosition).l
OrphanedShipJitter_Tick:                                ; was: loc_8AC2
                subq.w  #1,(ShipJitterTimer).l
                bne.w   Cutscene_Return
                move.w  #$88,(ShipJitterTimer).l
                subq.w  #2,(ShipJitterState).l
                rts
; End of function OrphanedShipJitter_IncrementPosition
; Queues eighteen pattern-row tilemaps and clears their reveal progress
ShipSequence_InitializePatternReveal:                   ; was: sub_8ADC
                move.w  #$A400,d0
                move.w  #$6022,d4
                movea.l #ShipPattern_RowTileStreams,a0
                move.w  #$11,d7
ShipSequence_QueueNextPatternRow:                       ; was: loc_8AEE
                jsr     ShipPattern_QueueRowTilemap(pc)  ; (pc)
                nop
                addi.w  #$80,d4
                dbf     d7,ShipSequence_QueueNextPatternRow
                lea     (ShipRowRevealProgress).l,a0
                move.w  #$11,d1
ShipSequence_ClearNextRowProgress:                      ; was: loc_8B06
                clr.w   (a0)+
                dbf     d1,ShipSequence_ClearNextRowProgress
                clr.w   (ShipRevealFrame).l
                move.b  #$30,d0                         ; '0'
                jsr     (Sound_QueueRequest).l
                move.l  #$8000,(ShipVerticalVelocity).l
                move.w  #$8000,(GlobalSpritePriorityBit).w
                bsr.w   ShipPattern_ClearBuffer
                addq.w  #2,(ShipSequenceState).l
; Reveals the staged pattern row by row while emitting radial star particles
ShipSequence_RevealPattern:                             ; was: loc_8B36
                bset    #0,(SceneSequenceFlags).w
                bsr.w   ShipSequence_ApplyPatternPalette
                bsr.w   ShipPattern_RevealRows
                bsr.w   ShipPattern_QueueBufferUpload
                bsr.w   ShipSequence_SpawnStarParticle
                cmpi.w  #$668,(ShipSequenceFrame).l
                bcs.w   Cutscene_Return
                movea.l #ShipSequence_ClearedArrivalTiles,a0
                jsr     (Tilemap_QueueIndexedRows).l
                clr.w   (GlobalSpritePriorityBit).w
                move.l  #Gfx_ScrollVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                move.w  #0,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                bclr    #0,(SceneSequenceFlags).w
                move.w  #$10,(ShipVerticalPosition).l
                clr.l   (ShipVerticalVelocity).l
                bsr.w   ShipSequence_UpdateVerticalScroll
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_InitializePatternReveal
; Advances background loading four steps per frame before starting the final fade
ShipSequence_WaitForBackgroundLoad:                     ; was: sub_8BA2
                bsr.w   ShipSequence_ApplyPatternPalette
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.w   Cutscene_Return
                move.w  #$FFF2,(ShipMainFadeStep).l
                move.w  #$E,(ShipAccentFadeStep).l
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_WaitForBackgroundLoad
; Fades the main and accent palettes in opposite directions, then removes the controller
ShipSequence_FadeOutPattern:                            ; was: sub_8BDE
                lea     (PaletteActiveBuffer).w,a0
                move.w  (ShipMainFadeStep).l,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                lea     (PaletteActiveColor16).w,a0
                move.w  (ShipAccentFadeStep).l,d0
                move.w  #$F,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Cutscene_Return
                subq.w  #2,(ShipAccentFadeStep).l
                addq.w  #2,(ShipMainFadeStep).l
                cmpi.w  #2,(ShipMainFadeStep).l
                bne.w   Cutscene_Return
                move.w  #$1000,2(a5)
                addq.w  #2,(ShipSequenceState).l
                rts
; End of function ShipSequence_FadeOutPattern
ShipSequence_Complete:                                  ; was: nullsub_20
                rts
; End of function ShipSequence_Complete

; Spawns one radial star particle around the moving pattern center
ShipSequence_SpawnStarParticle:                         ; was: sub_8C42
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Cutscene_Return
                lea     (Effect_StarParticleSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                jsr     (RandomNumber).l
                move.w  d0,d2
                andi.w  #$3F,d2                         ; '?'
                jsr     (RandomNumber).l
                andi.w  #$FE,d0
                addi.w  #$100,d0
                movem.l a0,-(sp)
                bsr.w   Math_LookupSineCosinePair
                movem.l (sp)+,a0
                muls.w  d2,d0
                move.l  d0,d3
                swap    d0
                addi.w  #$128,d0
                move.w  d0,$10(a0)
                asr.l   #4,d3
                move.l  d3,$18(a0)
                muls.w  d2,d1
                move.l  d1,d3
                swap    d1
                addi.w  #$180,d1
                add.w   (ShipVerticalPosition).l,d1
                move.w  (ShipSequenceFrame).l,d0
                subi.w  #$5C0,d0
                lsr.w   #1,d0
                add.w   d0,d1
                lsr.w   #2,d0
                add.w   d0,d1
                move.w  d1,$14(a0)
                asr.l   #4,d3
                move.l  d3,$1C(a0)
                rts
; End of function ShipSequence_SpawnStarParticle
; Applies fixed fade steps and restores five grayscale accent colors
ShipSequence_ApplyPatternPalette:                       ; was: sub_8CC0
                                        ; ShipSequence_WaitForBackgroundLoad   p
                lea     (PaletteActiveBuffer).w,a0
                move.w  #$FFF2,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                lea     (PaletteActiveColor16).w,a0
                move.w  #$E,d0
                move.w  #$F,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  #$222,(PaletteActiveColor59).w
                move.w  #$444,(PaletteActiveColor60).w
                move.w  #$666,(PaletteActiveColor61).w
                move.w  #$888,(PaletteActiveColor62).w
                move.w  #$AAA,(PaletteActiveColor63).w
                rts
; End of function ShipSequence_ApplyPatternPalette
; Integrates signed 16.16 vertical position and publishes it to V-scroll bands
ShipSequence_UpdateVerticalScroll:                      ; was: sub_8D0C
                                        ; ShipSequence_InitializePatternReveal+BA   p
                cmpi.w  #$1A,(ShipSequenceState).l
                bcc.w   Cutscene_Return
                move.l  (ShipVerticalVelocity).l,d0
                add.l   (ShipVerticalPosition).l,d0
                move.l  d0,(ShipVerticalPosition).l
                lea     (VScrollBuffer).w,a0
                move.w  (ShipVerticalPosition).l,d0
                neg.w   d0
                move.w  #$F,d7
ShipSequence_WriteMainVScroll:                          ; was: loc_8D3A
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,ShipSequence_WriteMainVScroll
                cmpi.w  #$18,(ShipSequenceState).l
                bcs.w   Cutscene_Return
                lea     (VScrollPlaneBColumn8).w,a0
                move.w  #4,d7
ShipSequence_WriteLowerVScroll:                         ; was: loc_8D56
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,ShipSequence_WriteLowerVScroll
                rts
; End of function ShipSequence_UpdateVerticalScroll
; Sets priority on `$160` staged arrival tiles and reloads their descriptor
ShipSequence_EnableArrivalPlanePriority:                ; was: sub_8D60
                lea     (ShipArrivalTilemap).l,a0
                move.w  #$15F,d1
ShipSequence_SetNextPriorityBit:                        ; was: loc_8D6A
                move.w  (a0),d0
                ori.w   #$8000,d0
                move.w  d0,(a0)+
                dbf     d1,ShipSequence_SetNextPriorityBit
                movea.l #ShipSequence_ArrivalPriorityTiles,a0
                jmp     Tilemap_QueueIndexedRows
; End of function ShipSequence_EnableArrivalPlanePriority
; Clears priority on `$160` staged arrival tiles and reloads their descriptor
ShipSequence_DisableArrivalPlanePriority:               ; was: sub_8D82
                lea     (ShipArrivalTilemap).l,a0
                move.w  #$15F,d1
ShipSequence_ClearNextPriorityBit:                      ; was: loc_8D8C
                move.w  (a0),d0
                andi.w  #$7FFF,d0
                move.w  d0,(a0)+
                dbf     d1,ShipSequence_ClearNextPriorityBit
                movea.l #ShipSequence_ArrivalPriorityTiles,a0
                jmp     Tilemap_QueueIndexedRows
; End of function ShipSequence_DisableArrivalPlanePriority
; ---------------------------------------------------------------------------
ShipSequence_TileBatch1:            dc.w    $4020, $2000, $100, $102  ; was: word_8DA4
ShipSequence_TileBatch2:            dc.w    $4220, $2000, $100, $304  ; was: word_8DAC
ShipSequence_TileBatch3:            dc.w    $4420, $2000, $100, $506  ; was: word_8DB4
ShipSequence_TileBatch4:            dc.w    $4620, $2000, $100, $708  ; was: word_8DBC
ShipSequence_TileBatch5:            dc.w    $4820, $2000, $200, $90A, $BFF  ; was: word_8DC4
ShipSequence_ArrivalPriorityTiles:  dc.w    $4020, $2000, $204, $102, 3, $400, $506, 7, $800, $90A, $BFF  ; was: word_8DCE
                                        ; ShipSequence_DisableArrivalPlanePriority+16   o
ShipSequence_ClearedArrivalTiles:   dc.w    $4020, $2000, $204, 0, 0, 0, 0, 0, 0, 0, $FF  ; was: word_8DE4

; Reveals progressively more of eighteen rows, one shuffled nibble per active row
ShipPattern_RevealRows:                                 ; was: sub_8DFA
                move.w  (ShipRevealFrame).l,d1
                addq.w  #1,(ShipRevealFrame).l
                lsr.w   #3,d1
                cmpi.w  #$11,d1
                bcs.s   ShipPattern_ClampVisibleRow
                move.w  #$11,d1
ShipPattern_ClampVisibleRow:                            ; was: loc_8E12
                lea     (ShipRowRevealProgress).l,a0
                lea     (CutsceneWorkBuffer).l,a2
ShipPattern_RevealNextRow:                              ; was: loc_8E1E
                movem.l a2,-(sp)
                bsr.w   ShipPattern_RevealNextNibble
                movem.l (sp)+,a2
                addq.w  #2,a0
                adda.w  #$20,a2                         ; ' '
                dbf     d1,ShipPattern_RevealNextRow
                rts
; End of function ShipPattern_RevealRows
; ORs the next shuffled four-bit mask into one word of a pattern row
ShipPattern_RevealNextNibble:                           ; was: sub_8E36
                move.w  (a0),d0
                cmpi.w  #$40,d0                         ; '@'
                beq.w   Cutscene_Return
                addq.w  #1,(a0)
                lea     PatternDissolveWordOrder(pc),a3
                lea     (a3,d0.w),a3
                moveq   #0,d2
                move.b  (a3),d2
                move.l  d2,d3
                andi.b  #3,d2
                lsl.b   #1,d2
                lea     ShipPattern_NibbleMasks(pc,d2.w),a4
                move.w  (a4),d2
                andi.b  #$3C,d3                         ; '<'
                lsr.b   #1,d3
                adda.l  d3,a2
                move.w  (a2),d4
                or.w    d2,d4
                move.w  d4,(a2)
                rts
; End of function ShipPattern_RevealNextNibble
; ---------------------------------------------------------------------------
ShipPattern_NibbleMasks:    dc.w    $F000, $F00, $F0, $F  ; was: word_8E6C

; Clears the complete `$240`-byte pattern workspace
ShipPattern_ClearBuffer:                                ; was: sub_8E74
                lea     (CutsceneWorkBuffer).l,a1
                moveq   #0,d0
                move.w  #$8F,d1
ShipPattern_ClearNextLongword:                          ; was: loc_8E80
                move.l  d0,(a1)+
                dbf     d1,ShipPattern_ClearNextLongword
; End of function ShipPattern_ClearBuffer
; Queues the fixed DMA command that uploads the pattern workspace
ShipPattern_QueueBufferUpload:                          ; was: sub_8E86
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94019320,(a0)+
                move.l  #$8F02977F,(a0)+
                move.l  #$96889500,(a0)+
                move.l  #$4D800082,(a0)+
                rts
; End of function ShipPattern_QueueBufferUpload
; Expands one `$FF`-terminated byte stream to words and queues its row DMA
ShipPattern_QueueRowTilemap:                            ; was: sub_8EAC
                movea.w (VDPStagingDataCursor).w,a1
                moveq   #0,d3
ShipPattern_CopyNextTileIndex:                          ; was: loc_8EB2
                move.b  (a0)+,d0
                cmpi.b  #$FF,d0
                beq.s   ShipPattern_EmitRowDMA
                move.w  d0,(a1)+
                addq.w  #1,d3
                bra.s   ShipPattern_CopyNextTileIndex
; ---------------------------------------------------------------------------
ShipPattern_EmitRowDMA:                                 ; was: loc_8EC0
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                move.w  d4,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009300,-(a1)
                move.b  d3,3(a1)
                move.w  a1,(VDPCommandQueueHead).w
                asl.w   #1,d3
                add.w   d3,(VDPStagingDataCursor).w
                rts
; End of function ShipPattern_QueueRowTilemap
; ---------------------------------------------------------------------------
ShipPattern_RowTileStreams: dc.w    $6C6C, $6C6C, $6C6C, $6CFF  ; was: word_8EFE
                dc.w    $6D6D, $6D6D, $6D6D, $6DFF
                dc.w    $6E6E, $6E6E, $6E6E, $6EFF
                dc.w    $6F6F, $6F6F, $6F6F, $6FFF
                dc.w    $7070, $7070, $7070, $70FF
                dc.w    $7171, $7171, $7171, $71FF
                dc.w    $7272, $7272, $7272, $72FF
                dc.w    $7373, $7373, $7373, $73FF
                dc.w    $7474, $7474, $7474, $74FF
                dc.w    $7575, $7575, $7575, $75FF
                dc.w    $7676, $7676, $7676, $76FF
                dc.w    $7777, $7777, $7777, $77FF
                dc.w    $7878, $7878, $7878, $78FF
                dc.w    $7979, $7979, $7979, $79FF
                dc.w    $7A7A, $7A7A, $7A7A, $7AFF
                dc.w    $7B7B, $7B7B, $7B7B, $7BFF
                dc.w    $7C7C, $7C7C, $7C7C, $7C7C
                dc.w    $FF7D, $7D7D, $7D7D, $7D7D
                dc.w    $7DFF
