Boss_FlyingNeoMain:                                     ; was: sub_3BFF6
                tst.w   4(a5)
                beq.w   Boss_FlyingNeoStateDispatch
                tst.w   $23C(a5)
                bmi.s   Boss_FlyingNeoProcessMainColorFade
                beq.s   Boss_FlyingNeoProcessMainColorFade
                bclr    #0,(BossColorEffectFlags).w
Boss_FlyingNeoProcessMainColorFade:                     ; was: loc_3C00C
                                        ; Boss_FlyingNeoMain+E   j
                lea     (PaletteFade_FlyingNeoEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                tst.w   8(a5)
                beq.s   Boss_FlyingNeoStateDispatch
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_FlyingNeoPublishScreenX
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_FlyingNeoPublishScreenX
                tst.w   $23C(a5)
                bmi.s   Boss_FlyingNeoCheckDefeat
                beq.s   Boss_FlyingNeoSelectHealthFadeThreshold
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_FlyingNeoCheckDefeat
                move.w  #$620,d0
                lea     (PaletteFade_FlyingNeoEntryOffsets).l,a2
                jsr     (Gfx_StepPaletteEntriesToColor).l
                bne.s   Boss_FlyingNeoCheckDefeat
                move.w  #$FFFF,$23C(a5)
                bra.s   Boss_FlyingNeoCheckDefeat
; ---------------------------------------------------------------------------
Boss_FlyingNeoSelectHealthFadeThreshold:                ; was: loc_3C05A
                move.w  #$2580,d0
                tst.w   (DifficultyMode).w
                beq.s   Boss_FlyingNeoCheckHealthFadeThreshold
                move.w  #$3880,d0
Boss_FlyingNeoCheckHealthFadeThreshold:                 ; was: loc_3C068
                cmp.w   (BossHealth).w,d0
                bmi.s   Boss_FlyingNeoCheckDefeat
                cmpi.w  #$2380,(BossHealth).w
                bpl.s   Boss_FlyingNeoSetSharedPhaseTwo
                move.w  #1,$23C(a5)
                bra.s   Boss_FlyingNeoCheckDefeat
; ---------------------------------------------------------------------------
Boss_FlyingNeoSetSharedPhaseTwo:                        ; was: loc_3C07E
                move.w  #2,(ColorFadeTriggerState).w
Boss_FlyingNeoCheckDefeat:                              ; was: loc_3C084
                                        ; Boss_FlyingNeoMain+48   j
                tst.w   (BossHealth).w
                beq.w   Boss_FlyingNeoDefeatInit
Boss_FlyingNeoPublishScreenX:                           ; was: loc_3C08C
                                        ; Boss_FlyingNeoMain+36   j
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $430(a5),d0
                move.w  d0,$BC(a5)
; State dispatcher for Flying Neo boss using jump table
Boss_FlyingNeoStateDispatch:                            ; was: loc_3C098
                                        ; Boss_FlyingNeoMain+26   j
                move.w  4(a5),d0
                movea.w Boss_FlyingNeoStateOffsets(pc,d0.w),a0
                adda.l  #Boss_FlyingNeoInit,a0
                jmp     (a0)
; End of function Boss_FlyingNeoMain
; ---------------------------------------------------------------------------
Boss_FlyingNeoStateOffsets: dc.w    Boss_FlyingNeoInit-Boss_FlyingNeoInit  ; was: off_3C0A8
                dc.w    Boss_FlyingNeoWaitForScrollingBackground-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoSetup-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoIntroDelayState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoWaitForPlayerSequenceState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoAttackStartDelayState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatConvertForwardSlotRangeState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatConvertReverseSlotRangeState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatLaunchType88PartState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatParticleRainState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatCompletionDelayState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDefeatScrollState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoPlayerControlled-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoPursuitState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoHorizontalSwoopState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoHoverDecisionState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoRisingRetreatState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoDivingArcState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoRisingArcState-Boss_FlyingNeoInit
                dc.w    Boss_FlyingNeoPartAnchorState-Boss_FlyingNeoInit

; Initializes Flying-Neo boss clearing sprites
Boss_FlyingNeoInit:                                     ; was: sub_3C0D0
                                        ; ROM:Boss_FlyingNeoStateOffsets   o
                addq.w  #2,4(a5)
                move.w  #1,8(a5)
                move.w  #$154,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                movea.w #(FlyingNeoSineTable-M68K_RAM),a0
                moveq   #$C,d0
                jsr     (Math_CalculateSineCosineTable).l
                bsr.s   Boss_FlyingNeoClearPaletteHighBits
                move.l  #Gfx_ScrollVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #$F00,(TilemapRowXOrFillWord).w
                move.w  #$F760,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
Boss_FlyingNeoInitOrWaitReturn:                         ; was: locret_3C10E
                rts
; End of function Boss_FlyingNeoInit
; Clears bit 15 in four palette-buffer ranges
Boss_FlyingNeoClearPaletteHighBits:                     ; was: sub_3C110
                                        ; Boss_FlyingNeoInit+22   p
                lea     (FlyingNeoTileAttrRangeA).l,a0
                move.w  #$7FFF,d0
                move.w  #$EF,d7
Boss_FlyingNeoClearPaletteHighBitsFirstRange:           ; was: loc_3C11E
                and.w   d0,(a0)+
                dbf     d7,Boss_FlyingNeoClearPaletteHighBitsFirstRange
                lea     (FlyingNeoTileAttrRangeB).l,a0
                move.w  #$F,d7
Boss_FlyingNeoClearPaletteHighBitsSecondRange:          ; was: loc_3C12E
                and.w   d0,(a0)+
                dbf     d7,Boss_FlyingNeoClearPaletteHighBitsSecondRange
                lea     (FlyingNeoTileAttrRangeC).l,a0
                move.w  #$2F,d7                         ; '/'
Boss_FlyingNeoClearPaletteHighBitsThirdRange:           ; was: loc_3C13E
                and.w   d0,(a0)+
                dbf     d7,Boss_FlyingNeoClearPaletteHighBitsThirdRange
                lea     (FlyingNeoTileAttrRangeD).l,a0
                move.w  #$2F,d7                         ; '/'
Boss_FlyingNeoClearPaletteHighBitsFourthRange:          ; was: loc_3C14E
                and.w   d0,(a0)+
                dbf     d7,Boss_FlyingNeoClearPaletteHighBitsFourthRange
                rts
; Waits for the scrolling-background helper to report completion
Boss_FlyingNeoWaitForScrollingBackground:               ; was: sub_3C156
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.s   Boss_FlyingNeoInitOrWaitReturn
                addq.w  #2,4(a5)
                clr.w   (GlobalSpritePriorityBit).w
                rts
; End of function Boss_FlyingNeoWaitForScrollingBackground
; Complex setup with metasprite and palette initialization
Boss_FlyingNeoSetup:                                    ; was: sub_3C168
                movea.w #(SecondaryEntityType-M68K_RAM),a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #8,d7
                movea.l #Boss_FlyingNeoMetaspriteDescriptors,a0
                movea.l #Boss_FlyingNeoPartRadii,a1
                movea.l #Boss_FlyingNeoPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                clr.w   $54(a5)
                clr.w   $56(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$D00,2(a5)
                bset    #0,$1E2(a5)
                bset    #0,$362(a5)
                move.w  #$10,d0
                moveq   #8,d1
                move.w  #$8080,d2
                movea.w #(EleventhEntityType-M68K_RAM),a0
                move.w  d0,(a0)
                move.w  #$C080,2(a0)
                move.w  #$4300,$E(a0)
                move.l  #Boss_FlyingNeoAuxiliaryPartMappingA,8(a0)
                move.b  #$18,$20(a0)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  d0,(a0)
                move.w  #$8080,2(a0)
                move.w  #$6398,$E(a0)
                move.w  #$D00,8(a0)
                move.b  #$18,$20(a0)
                movea.w #(TwelfthEntityType-M68K_RAM),a0
                lea     Boss_FlyingNeoAuxiliarySpriteDescriptorA(pc),a1
                nop
                moveq   #2,d7
                bsr.w   Boss_FlyingNeoInitializeAuxiliarySprites
                lea     Boss_FlyingNeoAuxiliarySpriteDescriptorB(pc),a1
                nop
                moveq   #1,d7
                bsr.w   Boss_FlyingNeoInitializeAuxiliarySprites
                lea     Boss_FlyingNeoAuxiliarySpriteDescriptorC(pc),a1
                nop
                moveq   #1,d7
                bsr.w   Boss_FlyingNeoInitializeAuxiliarySprites
                lea     Boss_FlyingNeoAuxiliarySpriteDescriptorD(pc),a1
                nop
                moveq   #1,d7
                bsr.w   Boss_FlyingNeoInitializeAuxiliarySprites
                movea.l #Boss_FlyingNeoObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                lea     (Boss_FlyingNeoPaletteCommands).l,a0
                jsr     (Gfx_LoadPalettePreservingSharedColor).l
                lea     (PaletteFade_FlyingNeoEntryOffsets).l,a2
                jsr     (Gfx_ClearColorFadeState).l
                move.w  #$28,(RasterEffectIndex).w      ; '('
                clr.w   (RasterEffectInitState).w
                move.w  #$C,(RasterLayoutOffset).w
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #6,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #2,$17E(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$80,$1DE(a5)
                clr.w   $54(a5)
                move.w  #$138,$10(a5)
                move.w  #$20,$14(a5)                    ; ' '
                bsr.w   Boss_FlyingNeoApplyFacingGraphics
; End of function Boss_FlyingNeoSetup
; Counts down the intro delay while maintaining the common pose
Boss_FlyingNeoIntroDelayState:                          ; was: sub_3C29C
                subq.w  #1,$1DE(a5)
                bmi.s   Boss_FlyingNeoAdvanceToPlayerSequenceWait
Boss_FlyingNeoUpdateIntroPose:                          ; was: loc_3C2A2
                                        ; Boss_FlyingNeoWaitForPlayerSequenceState+1E   j
                bsr.w   Boss_FlyingNeoUpdateVerticalOscillation
                lea     Boss_FlyingNeoNeutralPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bra.w   Boss_FlyingNeoUpdateSprites
; ---------------------------------------------------------------------------
; Advances from the intro delay into the player-sequence wait
Boss_FlyingNeoAdvanceToPlayerSequenceWait:              ; was: loc_3C2B4
                addq.w  #2,4(a5)
                moveq   #7,d0
                jsr     (BossMessage_Start).l
; Waits for the player sequence to finish before starting the attack delay
Boss_FlyingNeoWaitForPlayerSequenceState:               ; was: sub_3C2C0
                tst.w   (MessageSequenceState).w
                bne.s   Boss_FlyingNeoUpdateIntroPose
                addq.w  #2,4(a5)
                move.w  #$30,$1DE(a5)                   ; '0'
                subi.w  #$A0,(CameraXLowerBound).w
                clr.b   (BossColorEffectFlags).w
; Counts down the final delay before initializing the attack pattern
Boss_FlyingNeoAttackStartDelayState:                    ; was: loc_3C2DA
                subq.w  #1,$1DE(a5)
                bpl.s   Boss_FlyingNeoUpdateIntroPose
                bra.w   Boss_FlyingNeoBeginPursuitState
; End of function Boss_FlyingNeoWaitForPlayerSequenceState
; Initializes boss defeat sequence clearing flags
Boss_FlyingNeoDefeatInit:                               ; was: sub_3C2E4
                move.w  #$C,4(a5)
                clr.w   8(a5)
                clr.w   $48(a5)
                move.w  #$C6E0,$4A(a5)
                bsr.w   Boss_FlyingNeoSetLinkedPartFlag0
                clr.l   $18(a5)
                clr.l   $1C(a5)
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #4,(StageSpawnCountdown).w
; End of function Boss_FlyingNeoDefeatInit
; Converts one linked-object slot every six frames while walking forward
Boss_FlyingNeoDefeatConvertForwardSlotRangeState:       ; was: sub_3C31C
                bsr.w   Boss_FlyingNeoUpdatePaletteFade
                bsr.w   Boss_FlyingNeoUpdateDefeatEffectOrigin
                bsr.w   Boss_FlyingNeoBuildLineScrollTables
                subq.w  #1,$48(a5)
                bpl.s   Boss_FlyingNeoDefeatConvertForwardSlotRangeReturn
                move.w  #5,$48(a5)
                movea.w $4A(a5),a0
                addi.w  #$60,$4A(a5)                    ; '`'
                cmpi.w  #$C9E0,$4A(a5)
                bmi.s   Boss_FlyingNeoConvertNextForwardSlot
                addq.w  #2,4(a5)
                move.w  #$CD40,$4A(a5)
Boss_FlyingNeoConvertNextForwardSlot:                   ; was: loc_3C350
                bsr.w   Boss_FlyingNeoConvertPartToDefeatParticle
Boss_FlyingNeoDefeatConvertForwardSlotRangeReturn:      ; was: locret_3C354
                rts
; End of function Boss_FlyingNeoDefeatConvertForwardSlotRangeState
; Sets flag bit zero on 19 linked-object records
Boss_FlyingNeoSetLinkedPartFlag0:                       ; was: sub_3C356
                moveq   #0,d0
                movea.w #(SecondaryEntityFlags-M68K_RAM),a0
                moveq   #$12,d7
Boss_FlyingNeoSetNextLinkedPartFlag0:                   ; was: loc_3C35E
                bset    d0,(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_FlyingNeoSetNextLinkedPartFlag0
                rts
; End of function Boss_FlyingNeoSetLinkedPartFlag0
; Converts the linked record in A0 into an upward-moving defeat particle
Boss_FlyingNeoConvertPartToDefeatParticle:              ; was: sub_3C36A
                                        ; Boss_FlyingNeoDefeatConvertReverseSlotRangeState:Boss_FlyingNeoConvertNextReverseSlot   p
                movea.l #Projectile_SpawnSpriteFrames,a1  ; make offsets?
                jsr     (Sprite_InitFromTable).l
                clr.l   $18(a0)
                move.l  #$FFFEE000,$1C(a0)
                clr.b   $20(a0)
                move.b  #$BC,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Boss_FlyingNeoConvertPartToDefeatParticle
; Updates the defeat-effect origin from boss position and facing
Boss_FlyingNeoUpdateDefeatEffectOrigin:                 ; was: sub_3C390
                                        ; Boss_FlyingNeoDefeatConvertReverseSlotRangeState+4   p
                moveq   #$E,d0
                moveq   #$1C,d1
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoStoreDefeatEffectOrigin
                moveq   #$10,d0
Boss_FlyingNeoStoreDefeatEffectOrigin:                  ; was: loc_3C39C
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$70(a5)
                move.w  d1,$74(a5)
                rts
; End of function Boss_FlyingNeoUpdateDefeatEffectOrigin
; Converts one linked-object slot every five frames while walking backward
Boss_FlyingNeoDefeatConvertReverseSlotRangeState:       ; was: sub_3C3AE
                bsr.w   Boss_FlyingNeoUpdatePaletteFade
                bsr.w   Boss_FlyingNeoUpdateDefeatEffectOrigin
                bsr.w   Boss_FlyingNeoBuildLineScrollTables
                subq.w  #1,$48(a5)
                bpl.s   Boss_FlyingNeoDefeatConvertReverseSlotRangeReturn
                move.w  #4,$48(a5)
                movea.w $4A(a5),a0
                subi.w  #$60,$4A(a5)                    ; '`'
                cmpi.w  #$C9E0,$4A(a5)
                bne.s   Boss_FlyingNeoConvertNextReverseSlot
                addq.w  #2,4(a5)
Boss_FlyingNeoConvertNextReverseSlot:                   ; was: loc_3C3DC
                bsr.w   Boss_FlyingNeoConvertPartToDefeatParticle
Boss_FlyingNeoDefeatConvertReverseSlotRangeReturn:      ; was: locret_3C3E0
                rts
; End of function Boss_FlyingNeoDefeatConvertReverseSlotRangeState
; Waits, then launches the fixed type-$88 part from slot $FFC9E0
Boss_FlyingNeoDefeatLaunchType88PartState:              ; was: sub_3C3E2
                bsr.w   Boss_FlyingNeoUpdatePaletteFade
                bsr.w   Boss_FlyingNeoUpdateDefeatEffectOrigin
                bsr.w   Boss_FlyingNeoBuildLineScrollTables
                subq.w  #1,$48(a5)
                bpl.s   Boss_FlyingNeoDefeatLaunchType88PartReturn
                addq.w  #2,4(a5)
                move.w  #$70,$48(a5)                    ; 'p'
                bsr.w   Boss_FlyingNeoQueueFixedTileRowTransfer
                movea.w #(EleventhEntityType-M68K_RAM),a0
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.l  #$FFFEE000,$18(a0)
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoInitializeLaunchedType88Part
                neg.l   $18(a0)
Boss_FlyingNeoInitializeLaunchedType88Part:             ; was: loc_3C420
                jmp     Projectile_InitType88
; ---------------------------------------------------------------------------
Boss_FlyingNeoDefeatLaunchType88PartReturn:             ; was: locret_3C426
                rts
; End of function Boss_FlyingNeoDefeatLaunchType88PartState
; Emits randomized type-$88 particles before loading the final tile command
Boss_FlyingNeoDefeatParticleRainState:                  ; was: sub_3C428
                bsr.w   Boss_FlyingNeoUpdatePaletteFade
                bsr.w   Boss_FlyingNeoUpdateDefeatEffectOrigin
                bsr.w   Boss_FlyingNeoBuildLineScrollTables
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_FlyingNeoUpdateDefeatParticleRainTimer
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_FlyingNeoUpdateDefeatParticleRainTimer
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.l  #$FFFF1000,$1C(a0)
                jsr     (Projectile_InitType88).l
                clr.b   $20(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$1F,d1
                subi.w  #$20,d0                         ; ' '
                subi.w  #$10,d1
                add.w   $10(a5),d0
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoPositionDefeatRainParticle
                addi.w  #$20,d0                         ; ' '
Boss_FlyingNeoPositionDefeatRainParticle:               ; was: loc_3C486
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_FlyingNeoUpdateDefeatParticleRainTimer
                move.b  #$BC,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateDefeatParticleRainTimer:            ; was: loc_3C4A6
                                        ; Boss_FlyingNeoDefeatParticleRainState+1C   j
                subq.w  #1,$48(a5)
                bpl.s   Boss_FlyingNeoDefeatParticleRainReturn
                addq.w  #2,4(a5)
                move.w  #$10,$48(a5)
                move.w  #$1000,$62(a5)
                lea     Boss_FlyingNeoDefeatTileCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Boss_FlyingNeoDefeatParticleRainReturn:                 ; was: locret_3C4C8
                rts
; End of function Boss_FlyingNeoDefeatParticleRainState
; Counts down before publishing the final player-sequence value
Boss_FlyingNeoDefeatCompletionDelayState:               ; was: sub_3C4CA
                subq.w  #1,$48(a5)
                bpl.s   Boss_FlyingNeoDefeatScrollState
                addq.w  #2,4(a5)
                addq.w  #2,(StageStateOffset).w
                move.w  #$5C,(MessageSequenceState).w   ; '\'
; Updates scrolling after the defeat particle sequence
Boss_FlyingNeoDefeatScrollState:                        ; was: loc_3C4DE
                bra.w   Boss_FlyingNeoBuildLineScrollTables
; End of function Boss_FlyingNeoDefeatCompletionDelayState
; Flying-Neo boss player control input handler
Boss_FlyingNeoPlayerControlled:                         ; was: sub_3C4E2
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $23E(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                btst    #0,(ControllerHeldState).w
                beq.s   Boss_FlyingNeoPlayerControlCheckDown
                move.w  #$FFFF,$1C(a5)
                move.w  #$FFE0,$23E(a5)
Boss_FlyingNeoPlayerControlCheckDown:                   ; was: loc_3C50A
                btst    #1,(ControllerHeldState).w
                beq.s   Boss_FlyingNeoPlayerControlCheckRight
                move.w  #1,$1C(a5)
                move.w  #$20,$23E(a5)                   ; ' '
Boss_FlyingNeoPlayerControlCheckRight:                  ; was: loc_3C51E
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_FlyingNeoPlayerControlCheckLeft
                move.w  #2,$18(a5)
                move.w  #$100,$54(a5)
                bsr.w   Boss_FlyingNeoApplyFacingGraphics
Boss_FlyingNeoPlayerControlCheckLeft:                   ; was: loc_3C536
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_FlyingNeoApplyPlayerControlPose
                move.w  #$FFFE,$18(a5)
                move.w  #0,$54(a5)
                bsr.w   Boss_FlyingNeoApplyFacingGraphics
Boss_FlyingNeoApplyPlayerControlPose:                   ; was: loc_3C54E
                lea     Boss_FlyingNeoNeutralPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bra.w   Boss_FlyingNeoUpdateSprites
; End of function Boss_FlyingNeoPlayerControlled
; Begins the timed pursuit state and resets its motion submodes
Boss_FlyingNeoBeginPursuitState:                        ; was: sub_3C55C
                                        ; Boss_FlyingNeoHoverDecisionState+12   j
                move.w  #$1A,4(a5)
                clr.w   $17E(a5)
                clr.w   $1DC(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3FF,d0
                addi.w  #$40,d0                         ; '@'
                move.w  d0,$1DE(a5)
; Restores self-anchored part links and the neutral part mappings
Boss_FlyingNeoSetNeutralPartAnchors:                    ; was: loc_3C57A
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #Boss_FlyingNeoAnchorPartMappingB,$1E8(a5)
                move.l  #Boss_FlyingNeoAnchorPartMappingB,$368(a5)
; End of function Boss_FlyingNeoBeginPursuitState
; Pursues the player while applying vertical oscillation and timed reversals
Boss_FlyingNeoPursuitState:                             ; was: sub_3C592
                subq.w  #1,$1DE(a5)
                bmi.w   Boss_FlyingNeoBeginHorizontalSwoopState
                bsr.w   Boss_FlyingNeoUpdateVerticalOscillation
                bsr.w   Boss_FlyingNeoGetTrackedPartPlayerDelta
                bsr.s   Boss_FlyingNeoUpdatePursuitHorizontalMotion
                cmpi.w  #$1A,4(a5)
                beq.s   Boss_FlyingNeoUpdatePursuitPose
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdatePursuitPose:                        ; was: loc_3C5AE
                lea     Boss_FlyingNeoNeutralPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bra.w   Boss_FlyingNeoUpdateSprites
; End of function Boss_FlyingNeoPursuitState
; Accelerates toward the player or runs the active short reversal
Boss_FlyingNeoUpdatePursuitHorizontalMotion:            ; was: sub_3C5BC
                move.b  (RandomNumberState+1).w,d5
                move.b  (RandomNumberState).w,d6
                move.w  (FrameCounter).w,d7
                asr.w   #2,d7
                andi.w  #$40,d7                         ; '@'
                add.w   d7,d0
                tst.w   $54(a5)
                beq.w   Boss_FlyingNeoUpdateLeftwardPursuitMotion
                tst.w   d1
                bmi.w   Boss_FlyingNeoBeginHorizontalSwoopState
                tst.w   $1DC(a5)
                bne.s   Boss_FlyingNeoUpdateRightwardReversal
                cmpi.l  #$2C000,$18(a5)
                bpl.s   Boss_FlyingNeoCheckRightwardCloseRangeManeuver
                addi.l  #$3200,$18(a5)
Boss_FlyingNeoCheckRightwardCloseRangeManeuver:         ; was: loc_3C5F6
                bsr.w   Boss_FlyingNeoSelectCloseRangeManeuver
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateRightwardReversal:                  ; was: loc_3C5FC
                subq.w  #1,$11C(a5)
                bpl.s   Boss_FlyingNeoAccelerateReversalLeft
Boss_FlyingNeoFinishPursuitReversal:                    ; was: loc_3C602
                clr.w   $1DC(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoAccelerateReversalLeft:                   ; was: loc_3C608
                cmpi.l  #$FFFC2000,$18(a5)
                bmi.s   Boss_FlyingNeoRightwardReversalReturn
                addi.l  #-$4200,$18(a5)
Boss_FlyingNeoRightwardReversalReturn:                  ; was: locret_3C61A
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateLeftwardPursuitMotion:              ; was: loc_3C61C
                tst.w   d1
                bpl.w   Boss_FlyingNeoBeginHorizontalSwoopState
                tst.w   $1DC(a5)
                bne.s   Boss_FlyingNeoUpdateLeftwardReversal
                cmpi.l  #$FFFD4000,$18(a5)
                bmi.s   Boss_FlyingNeoCheckLeftwardCloseRangeManeuver
                addi.l  #-$3200,$18(a5)
Boss_FlyingNeoCheckLeftwardCloseRangeManeuver:          ; was: loc_3C63A
                cmpi.w  #$E4,d0
                bpl.s   Boss_FlyingNeoLeftwardPursuitReturn
                bsr.w   Boss_FlyingNeoSelectCloseRangeManeuver
Boss_FlyingNeoLeftwardPursuitReturn:                    ; was: locret_3C644
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateLeftwardReversal:                   ; was: loc_3C646
                subq.w  #1,$11C(a5)
                bmi.s   Boss_FlyingNeoFinishPursuitReversal
                cmpi.l  #$3E000,$18(a5)
                bpl.s   Boss_FlyingNeoLeftwardReversalReturn
                addi.l  #$4200,$18(a5)
Boss_FlyingNeoLeftwardReversalReturn:                   ; was: locret_3C65E
                rts
; End of function Boss_FlyingNeoUpdatePursuitHorizontalMotion
; Selects a short reversal or the rising retreat when the player is nearby
Boss_FlyingNeoSelectCloseRangeManeuver:                 ; was: sub_3C660
                                        ; Boss_FlyingNeoUpdatePursuitHorizontalMotion+84   p
                cmpi.w  #$D4,d0
                bpl.s   Boss_FlyingNeoCloseRangeManeuverReturn
                move.w  (FrameCounter).w,d0
                btst    #9,d0
                beq.s   Boss_FlyingNeoStartPursuitReversal
                andi.w  #1,d0
                beq.w   Boss_FlyingNeoBeginRisingRetreatState
Boss_FlyingNeoStartPursuitReversal:                     ; was: loc_3C678
                addq.w  #2,$1DC(a5)
                andi.w  #$F,d6
                addq.w  #3,d6
                move.w  d6,$11C(a5)
Boss_FlyingNeoCloseRangeManeuverReturn:                 ; was: locret_3C686
                rts
; End of function Boss_FlyingNeoSelectCloseRangeManeuver
; Oscillates vertically between the upper and lower bands with random turns
Boss_FlyingNeoUpdateVerticalOscillation:                ; was: sub_3C688
                                        ; Boss_FlyingNeoPursuitState+8   p
                move.w  $14(a5),d7
                move.l  $1C(a5),d6
                move.w  (RandomNumberState).w,d0
                tst.w   $17E(a5)
                bne.w   Boss_FlyingNeoSelectDownwardOscillation
Boss_FlyingNeoSelectUpwardOscillation:                  ; was: loc_3C69C
                                        ; Boss_FlyingNeoUpdateVerticalOscillation+54   j
                clr.w   $17E(a5)
                cmpi.w  #$B0,d7
                bmi.s   Boss_FlyingNeoSelectDownwardOscillation
                cmpi.w  #$C6,d7
                bpl.s   Boss_FlyingNeoAccelerateUpward
                andi.w  #7,d0
                beq.s   Boss_FlyingNeoSelectDownwardOscillation
Boss_FlyingNeoAccelerateUpward:                         ; was: loc_3C6B2
                cmpi.l  #$FFFEE000,d6
                bmi.s   Boss_FlyingNeoVerticalOscillationReturn
                addi.l  #-$1E00,d6
                move.l  d6,$1C(a5)
Boss_FlyingNeoVerticalOscillationReturn:                ; was: locret_3C6C4
                                        ; Boss_FlyingNeoUpdateVerticalOscillation+5C   j
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoSelectDownwardOscillation:                ; was: loc_3C6C6
                                        ; Boss_FlyingNeoUpdateVerticalOscillation+1C   j
                move.w  #2,$17E(a5)
                cmpi.w  #$DC,d7
                bpl.s   Boss_FlyingNeoSelectUpwardOscillation
                cmpi.w  #$C6,d7
                bmi.s   Boss_FlyingNeoAccelerateDownward
                andi.w  #7,d0
                beq.s   Boss_FlyingNeoSelectUpwardOscillation
Boss_FlyingNeoAccelerateDownward:                       ; was: loc_3C6DE
                cmpi.l  #$12000,d6
                bpl.s   Boss_FlyingNeoVerticalOscillationReturn
                addi.l  #$1E00,d6
                move.l  d6,$1C(a5)
                rts
; End of function Boss_FlyingNeoUpdateVerticalOscillation
; Enters the horizontal swoop state with neutral self-anchored parts
Boss_FlyingNeoBeginHorizontalSwoopState:                ; was: sub_3C6F2
                                        ; Boss_FlyingNeoUpdatePursuitHorizontalMotion+1E   j
                move.w  #$1C,4(a5)
                move.l  #Boss_FlyingNeoAnchorPartMappingB,$1E8(a5)
                move.l  #Boss_FlyingNeoAnchorPartMappingB,$368(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; End of function Boss_FlyingNeoBeginHorizontalSwoopState
; Sweeps horizontally toward the facing-side screen boundary while rising
Boss_FlyingNeoHorizontalSwoopState:                     ; was: sub_3C71A
                subi.l  #$E00,$1C(a5)
                tst.w   $54(a5)
                bne.s   Boss_FlyingNeoUpdateRightwardSwoop
                cmpi.w  #$E80,$BC(a5)
                bmi.w   Boss_FlyingNeoBeginHoverDecisionState
                cmpi.l  #$FFFAA000,$18(a5)
                bmi.s   Boss_FlyingNeoUpdateSwoopPose
                addi.l  #-$4200,$18(a5)
                bra.s   Boss_FlyingNeoUpdateSwoopPose
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateRightwardSwoop:                     ; was: loc_3C746
                cmpi.w  #$1120,$BC(a5)
                bpl.w   Boss_FlyingNeoBeginHoverDecisionState
                cmpi.l  #$56000,$18(a5)
                bpl.s   Boss_FlyingNeoUpdateSwoopPose
                addi.l  #$4200,$18(a5)
Boss_FlyingNeoUpdateSwoopPose:                          ; was: loc_3C762
                                        ; Boss_FlyingNeoHorizontalSwoopState+2A   j
                lea     Boss_FlyingNeoHorizontalSwoopPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bra.w   Boss_FlyingNeoUpdateSprites
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginHoverDecisionState:                  ; was: loc_3C770
                                        ; Boss_FlyingNeoHorizontalSwoopState+32   j
                move.w  #$1E,4(a5)
                move.w  #$C0,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$1DE(a5)
                clr.w   $54(a5)
                cmpi.w  #$FD0,$BC(a5)
                bpl.s   Boss_FlyingNeoApplyPostSwoopFacing
                move.w  #$100,$54(a5)
Boss_FlyingNeoApplyPostSwoopFacing:                     ; was: loc_3C7AE
                bsr.w   Boss_FlyingNeoApplyFacingGraphics
; End of function Boss_FlyingNeoHorizontalSwoopState
; Hover decision state choosing next attack pattern
