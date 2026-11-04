Boss_ZLeoRotateAttackPalette:                           ; was: sub_52512
                                        ; Boss_ZLeoBeginRisingReturn+60   p
                move.w  (FrameCounter).w,d0
                asl.w   #3,d0
                andi.w  #$18,d0
                move.w  Boss_ZLeoAttackPaletteCycleTable(pc,d0.w),(PaletteActiveColor50).w
                move.w  Boss_ZLeoAttackPaletteCycleTable+2(pc,d0.w),(PaletteActiveColor62).w
                move.w  Boss_ZLeoAttackPaletteCycleTable+4(pc,d0.w),(PaletteActiveColor63).w
                rts
; End of function Boss_ZLeoRotateAttackPalette
; ---------------------------------------------------------------------------
Boss_ZLeoAttackPaletteCycleTable:   binclude "data/palettes/052530.bin"  ; was: word_52530
                                        ; Boss_ZLeoRotateAttackPalette+10   r

; Begin the rising return from the scrolling drop attack
Boss_ZLeoBeginRisingReturn:                             ; was: sub_52550
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$2400000,d0
                move.l  d0,$35C(a5)
                addi.w  #$F0,$35C(a5)
                move.w  #$E000,$59E(a5)
                clr.w   $11C(a5)
                move.w  #$200,$5B4(a5)
; Raise the vertical base to $F0, then enter the post-attack delay
Boss_ZLeoRunRisingReturn:                               ; was: loc_5257E
                move.l  $41C(a5),d0
                add.l   d0,$35C(a5)
                bsr.w   Boss_ZLeoAdvanceVerticalScrollAndQueueRow
                tst.w   $11C(a5)
                beq.w   Boss_ZLeoPrepareRisingReturnPose
Boss_ZLeoCheckRisingReturnComplete:                     ; was: loc_52592
                cmpi.w  #$F0,$35C(a5)
                bmi.s   Boss_ZLeoBeginPostAttackDelay
                lea     Boss_ZLeoRisingReturnPose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoPrepareRisingReturnPose:                       ; was: loc_525A4
                move.w  #$FFF6,$59C(a5)
                tst.w   (ZLeoDropProjectileFlag).w
                beq.s   Boss_ZLeoSelectRisingReturnPose
                bsr.w   Boss_ZLeoRotateAttackPalette
Boss_ZLeoSelectRisingReturnPose:                        ; was: loc_525B4
                move.w  $5B4(a5),d0
                addq.w  #4,d0
                cmp.w   (Entity57YPos).w,d0
                bpl.s   Boss_ZLeoRenderRisingThresholdPose
                move.b  #$F0,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #1,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bra.s   Boss_ZLeoCheckRisingReturnComplete
; ---------------------------------------------------------------------------
Boss_ZLeoRenderRisingThresholdPose:                     ; was: loc_525DA
                lea     Boss_ZLeoRisingThresholdPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginPostAttackDelay:                          ; was: loc_525E4
                addq.w  #2,4(a5)
                move.l  #$100000,(SecondaryCameraYPos).w
                move.l  #$F00000,$35C(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                bclr    #1,(BossColorEffectFlags).w
                move.b  #$10,$21(a5)
; Hold the restored position before returning to attack selection
Boss_ZLeoRunPostAttackDelay:                            ; was: loc_5260A
                subq.w  #1,$11C(a5)
                bpl.s   Boss_ZLeoRenderPostAttackDelay
                move.w  #$80,$11C(a5)
                bra.w   Boss_ZLeoBeginAttackSelection
; ---------------------------------------------------------------------------
Boss_ZLeoRenderPostAttackDelay:                         ; was: loc_5261A
                lea     Boss_ZLeoRisingReturnPose(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
; Synchronize the external stage coordinate before the common render tail
Boss_ZLeoSyncStageCoordinateAndRender:                  ; was: loc_52624
                                        ; Boss_ZLeoRunBattleReadyPose+30   j
                move.w  $5B4(a5),d0
                addq.w  #4,d0
                move.w  d0,(Entity57YPos).w
; Update pose segments, composite sprites, tiles, graphics, and flash color
Boss_ZLeoRenderCompositeFrame:                          ; was: loc_5262E
                                        ; Boss_ZLeoRunIntroCountdown+24   j
                bsr.w   Boss_ZLeoInterpretAndApplyPose
                moveq   #$F,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                move.w  #$120,d0
                sub.w   $10(a5),d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  $14(a5),d0
                addi.w  #-$104,d0
                sub.w   (PlaneAShakeOffset).w,d0
                move.w  d0,(PrimaryCameraYPosition).w
                bsr.w   Boss_ZLeoUpdateBladeDirectionFrame
                bsr.w   Boss_ZLeoUpdateThreeSpriteRows
                bsr.w   Boss_ZLeoUpdateTwoSpriteColumns
                bsr.w   Boss_ZLeoStreamTileChunkForCameraY
                bsr.w   Boss_ZLeoBuildHBlankRegisterBuffer
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_ZLeoUseAlternateFlashColor
                move.w  #$8C,(PaletteActiveColor63).w
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoUseAlternateFlashColor:                        ; was: loc_5267A
                move.w  #$2EE,(PaletteActiveColor63).w
                rts
; End of function Boss_ZLeoBeginRisingReturn
; Stream or clear one six-index tile chunk when camera Y crosses a threshold
Boss_ZLeoStreamTileChunkForCameraY:                     ; was: sub_52682
                                        ; Boss_ZLeoBeginRisingReturn+112   p
                movea.w #(ZLeoTileDMARecord-M68K_RAM),a3
                lea     Boss_ZLeoTileVramDestinations(pc),a4
                nop
                move.w  (ZLeoTileScrollIndex).w,d7
                move.w  (PrimaryCameraYPosition).w,d0
                addi.w  #$20,d0                         ; ' '
                bmi.w   Boss_ZLeoNoOp
                move.w  (ZLeoPreviousCameraY).w,d1
                move.w  d0,(ZLeoPreviousCameraY).w
                cmp.w   d1,d0
                beq.w   Boss_ZLeoNoOp
                lea     Boss_ZLeoTileScrollThresholds(pc),a0
                nop
                bpl.s   Boss_ZLeoQueueTileChunkClear
                cmp.w   2(a0,d7.w),d0
                bpl.w   Boss_ZLeoNoOp
                addq.w  #2,(ZLeoTileScrollIndex).w
                move.w  (a4,d7.w),(a3)+
                move.w  #$2000,(a3)+
                move.b  #5,(a3)+
                move.b  #0,(a3)+
                lea     Boss_ZLeoTileChunkIndexTable(pc),a1
                nop
                asl.w   #1,d7
                movea.l (a1,d7.w),a1
                move.l  (a1)+,(a3)+
                move.w  (a1)+,(a3)+
                bra.w   Boss_ZLeoExecuteTileChunkTransfer
; ---------------------------------------------------------------------------
; Queue a zero-index row when scrolling back across a tile-stream threshold
Boss_ZLeoQueueTileChunkClear:                           ; was: loc_526E2
                cmp.w   (a0,d7.w),d0
                bmi.w   Boss_ZLeoNoOp
                subq.w  #2,(ZLeoTileScrollIndex).w
                move.w  -2(a4,d7.w),(a3)+
                move.w  #$2000,(a3)+
                move.b  #5,(a3)+
                move.b  #0,(a3)+
                moveq   #0,d0
                move.l  d0,(a3)+
                move.w  d0,(a3)+
Boss_ZLeoExecuteTileChunkTransfer:                      ; was: loc_52704
                movea.w #(ZLeoTileDMARecord-M68K_RAM),a0
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_ZLeoStreamTileChunkForCameraY
; ---------------------------------------------------------------------------
Boss_ZLeoTileScrollThresholds:  dc.w    $7FFF, $C0, $A0, $80, $60, $40, $20, 0  ; was: word_5270E
Boss_ZLeoTileVramDestinations:  dc.w    $4410, $4610, $4810, $4A10, $4C10, $4E10  ; was: word_5271E
Boss_ZLeoTileChunkIndexTable:   dc.l    Boss_ZLeoTileChunkIndices0  ; was: off_5272A
                dc.l    Boss_ZLeoTileChunkIndices1
                dc.l    Boss_ZLeoTileChunkIndices2
                dc.l    Boss_ZLeoTileChunkIndices3
                dc.l    Boss_ZLeoTileChunkIndices4
                dc.l    Boss_ZLeoTileChunkIndices5
Boss_ZLeoTileChunkIndices0: dc.b    0, 0, 1, 2, 0, 0    ; was: byte_52742
Boss_ZLeoTileChunkIndices1: dc.b    3, 4, 5, 6, 7, 8    ; was: byte_52748
Boss_ZLeoTileChunkIndices2: dc.b    9, $A, $B, $C, $D, $E  ; was: byte_5274E
Boss_ZLeoTileChunkIndices3: dc.b    0, $F, $10, $11, $12, 0  ; was: byte_52754
Boss_ZLeoTileChunkIndices4: dc.b    0, $13, $14, $15, $16, 0  ; was: byte_5275A
Boss_ZLeoTileChunkIndices5: dc.b    $17, $18, $19, $1A, $1B, $1C  ; was: byte_52760

; Set the high-priority sprite bit on six Z-Leo parts
Boss_ZLeoSetSixPartsHighPriority:                       ; was: sub_52766
                moveq   #7,d0
                bset    d0,$7EE(a5)
                bset    d0,$90E(a5)
                bset    d0,$A2E(a5)
                bset    d0,$84E(a5)
                bset    d0,$96E(a5)
                bset    d0,$A8E(a5)
                rts
; End of function Boss_ZLeoSetSixPartsHighPriority
; Unreferenced inverse that clears the high-priority bit on the same six parts
UnreferencedBoss_ZLeoClearSixPartsHighPriority:         ; was: sub_52782
                moveq   #7,d0
                bclr    d0,$7EE(a5)
                bclr    d0,$90E(a5)
                bclr    d0,$A2E(a5)
                bclr    d0,$84E(a5)
                bclr    d0,$96E(a5)
                bclr    d0,$A8E(a5)
                rts
; End of function UnreferencedBoss_ZLeoClearSixPartsHighPriority
; Initialize the no-op object whose coordinates drive Z-Leo stage scroll effects
Boss_ZLeoInitializeStageScrollControlObject:            ; was: sub_5279E
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  #$40C,(a0)
                move.w  #$400,2(a0)
                clr.w   $56(a0)
                move.b  #$20,$21(a0)                    ; ' '
                move.w  #6,$46(a0)
                move.l  #$FF000100,$28(a0)
                move.w  #$150,d6
                move.w  #$120,d7
                move.w  d6,$10(a0)
                move.w  d7,$14(a0)
                move.w  d6,$48(a0)
                move.w  d7,$4C(a0)
                rts
; End of function Boss_ZLeoInitializeStageScrollControlObject
; Load the tile set used by Z-Leo phase transitions
Boss_ZLeoLoadPhaseTiles:                                ; was: sub_527DE
                                        ; Boss_ZLeoBeginAttackSelection+70   p
                lea     Boss_ZLeoPhaseTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_ZLeoLoadPhaseTiles
; ---------------------------------------------------------------------------
Boss_ZLeoPhaseTileLoadDescriptor:   dc.w    $4820, $2000, $100, $B0C  ; was: word_527EA

; Load the primary tiles used by battle entry and defeat effects
Boss_ZLeoLoadPrimaryTiles:                              ; was: sub_527F2
                                        ; Boss_ZLeoBeginDefeatSequence+46   p
                lea     Boss_ZLeoPrimaryTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_ZLeoLoadPrimaryTiles
; ---------------------------------------------------------------------------
Boss_ZLeoPrimaryTileLoadDescriptor: dc.w    $4820, $2000, $100, $1F20  ; was: word_527FE

; Build four HBlank segments of VDP register writes in FF9E00
Boss_ZLeoBuildHBlankRegisterBuffer:                     ; was: sub_52806
                                        ; Boss_ZLeoIntroInit   p
                movea.w #(ZLeoRasterBuildBuffer-M68K_RAM),a0
                move.w  (PrimaryCameraYPosition).w,d7
                neg.w   d7
                move.w  (Entity57YPos).w,d0
                subi.w  #$8B,d0
                beq.s   Boss_ZLeoClampFirstHBlankLine
                bmi.s   Boss_ZLeoClampFirstHBlankLine
                cmpi.w  #$DE,d0
                bmi.s   Boss_ZLeoWriteFirstHBlankSegment
Boss_ZLeoClampFirstHBlankLine:                          ; was: loc_52822
                                        ; Boss_ZLeoBuildHBlankRegisterBuffer+14   j
                move.w  #$FF,d0
Boss_ZLeoWriteFirstHBlankSegment:                       ; was: loc_52826
                ori.w   #$8A00,d0
                move.w  d0,(a0)+
                move.w  d7,(a0)+
                move.w  #$8B00,(a0)+
                move.w  #$8230,(a0)+
                move.w  #$8A1F,d2
                cmpi.w  #$148,(Entity57YPos).w
                bmi.s   Boss_ZLeoWriteRemainingHBlankSegments
                move.w  #$8AFF,d2
Boss_ZLeoWriteRemainingHBlankSegments:                  ; was: loc_52846
                move.w  d2,(a0)+
                move.w  d7,(a0)+
                move.w  #$8B00,(a0)+
                move.w  #$8230,(a0)+
                move.w  #$8AFF,(a0)+
                move.w  (Entity57YPos).w,d1
                addi.w  #$98,d1
                neg.w   d1
                move.w  d1,(a0)+
                move.w  #$8B02,(a0)+
                move.w  #$8210,(a0)+
                move.w  #$8AFF,(a0)+
                move.w  d7,(a0)+
                move.w  #$8B00,(a0)+
                move.w  #$8230,(a0)+
                rts
; End of function Boss_ZLeoBuildHBlankRegisterBuffer
; Load the initial composite tiles and set command word $81 on four queued transfers
Boss_ZLeoLoadInitialTilesAndSetCommand81:               ; was: sub_5287A
                movea.l #Boss_ZLeoInitialTileLoadData,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$81,d0
                moveq   #3,d7
                jmp     VDPQueue_SetCommandHighWord
; End of function Boss_ZLeoLoadInitialTilesAndSetCommand81
; ---------------------------------------------------------------------------
Boss_ZLeoInitialTileLoadData:   dc.w    $4E00, $4000, $900, $2A2B, $2A2B, $2A2B, $2A2B, $2A2B, $4E00, $4000, $900, $2D2E, $2D2E, $2D2E, $2D2E, $2D2E  ; was: word_52892

; Select the blade sprite frame from its four-direction mapping table
Boss_ZLeoUpdateBladeDirectionFrame:                     ; was: sub_528B2
                lea     Boss_ZLeoBladeDirectionFrameTable(pc),a1
                nop
                movea.w #(SeventhEntityType-M68K_RAM),a0
                andi.w  #$E7FF,$E(a0)
                jmp     Sprite_UpdateFourDirectionFrame
; End of function Boss_ZLeoUpdateBladeDirectionFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBladeDirectionFrameTable:  dc.l    Boss_ZLeoBladeDirectionMapping0  ; was: off_528C8
                dc.l    Boss_ZLeoBladeDirectionMapping1
                dc.l    Boss_ZLeoBladeDirectionMapping2
                dc.l    Boss_ZLeoBladeDirectionMapping3

; Position three rows of three sprite objects from the current pose channel
Boss_ZLeoUpdateThreeSpriteRows:                         ; was: sub_528D8
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  $34(a0),d2
                ext.w   d2
                movea.w #(TwentyFirstEntityType-M68K_RAM),a0
                moveq   #$FFFFFFFE,d0
                moveq   #$FFFFFFF6,d1
                bsr.s   Boss_ZLeoPositionThreeSpriteRow
                movea.w #(TwentyFourthEntityType-M68K_RAM),a0
                moveq   #0,d0
                moveq   #0,d1
                bsr.s   Boss_ZLeoPositionThreeSpriteRow
                movea.w #(TwentySeventhEntityType-M68K_RAM),a0
                moveq   #2,d0
                moveq   #$A,d1
; End of function Boss_ZLeoUpdateThreeSpriteRows
; Position one three-sprite row from its base offsets and pose-channel value
Boss_ZLeoPositionThreeSpriteRow:                        ; was: sub_528FE
                                        ; Boss_ZLeoUpdateThreeSpriteRows+1C   p
                add.w   $5B0(a5),d1
                move.w  d1,$10(a0)
                add.w   d0,d1
                move.w  d1,$70(a0)
                add.w   d0,d1
                move.w  d1,$D0(a0)
                moveq   #$FFFFFFF4,d0
                move.w  $5B4(a5),d4
                move.w  d2,d3
                add.w   d4,d3
                add.w   d0,d3
                move.w  d3,$D4(a0)
                move.w  d2,d3
                asr.w   #1,d3
                add.w   d4,d3
                add.w   d0,d3
                move.w  d3,$74(a0)
                move.w  d2,d3
                asr.w   #2,d3
                add.w   d4,d3
                add.w   d0,d3
                move.w  d3,$14(a0)
                rts
; End of function Boss_ZLeoPositionThreeSpriteRow
; Position the two three-sprite columns on opposite sides of Z-Leo
Boss_ZLeoUpdateTwoSpriteColumns:                        ; was: sub_5293C
                movea.w #(ThirtiethEntityType-M68K_RAM),a0
                move.w  #$FFDE,d0
                bsr.s   Boss_ZLeoPositionThreeSpriteColumn
                movea.w #(ThirtyThirdEntityType-M68K_RAM),a0
                move.w  #$22,d0                         ; '"'
; End of function Boss_ZLeoUpdateTwoSpriteColumns
; Position one three-sprite column and advance its optional separation timer
Boss_ZLeoPositionThreeSpriteColumn:                     ; was: sub_5294E
                move.w  #$FFD7,d1
                move.w  $48(a0),d2
                beq.s   Boss_ZLeoApplyThreeSpriteColumnPositions
                subq.w  #1,d2
                move.w  d2,$48(a0)
Boss_ZLeoApplyThreeSpriteColumnPositions:               ; was: loc_5295E
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.w  d0,$70(a0)
                move.w  d0,$D0(a0)
                add.w   $14(a5),d1
                add.w   d2,d1
                move.w  d1,$14(a0)
                asr.w   #1,d2
                addi.w  #-$20,d1
                add.w   d2,d1
                move.w  d1,$74(a0)
                addi.w  #-$1C,d1
                add.w   d2,d1
                move.w  d1,$D4(a0)
                rts
; End of function Boss_ZLeoPositionThreeSpriteColumn
; Apply Z-Leo's defeat palette target and screen-shake levels
Boss_ZLeoUpdateDefeatPaletteFadeAndShake:               ; was: sub_52990
                                        ; Boss_ZLeoRunDefeatWhiteout:Boss_ZLeoUpdateDefeatWhiteoutFade   p
                move.w  #6,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                move.w  $11C(a5),d0
                asl.w   #1,d0
                cmpi.w  #$E,d0
                bmi.s   Boss_ZLeoApplyDefeatPaletteFade
                moveq   #$E,d0
Boss_ZLeoApplyDefeatPaletteFade:                        ; was: loc_529AA
                movea.w #(PaletteActiveColor01-M68K_RAM),a0
                moveq   #$F,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  $11C(a5),d0
                movea.w #(PaletteActiveColor33-M68K_RAM),a0
                moveq   #$1E,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_ZLeoUpdateDefeatPaletteFadeAndShake
; Update the defeat explosion and spawn one randomized debris or particle effect
Boss_ZLeoSpawnDefeatEffect:                             ; was: sub_529CE
                                        ; Boss_ZLeoBeginDefeatSequence+9C   p
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_ZLeoSpawnDefeatEffectReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                bne.s   Boss_ZLeoInitDefeatParticle
                jsr     (Effect_InitDebrisSprite).l
                bra.w   Boss_ZLeoPositionDefeatEffect
; ---------------------------------------------------------------------------
Boss_ZLeoInitDefeatParticle:                            ; was: loc_529F0
                jsr     (Sprite_InitType160).l
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  #$FFFE,$1C(a0)
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ZLeoPositionDefeatEffect
                move.l  #Effect_SpriteAnimation01,8(a0)
                clr.w   $1C(a0)
Boss_ZLeoPositionDefeatEffect:                          ; was: loc_52A24
                                        ; Boss_ZLeoSpawnDefeatEffect+48   j
                move.b  #0,$20(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$7F,d0
                andi.w  #$7F,d1
                subi.w  #$40,d0                         ; '@'
                subi.w  #$20,d1                         ; ' '
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_ZLeoSpawnDefeatEffectReturn:                       ; was: locret_52A52
                rts
; End of function Boss_ZLeoSpawnDefeatEffect
; Accelerate the defeat-stage scroll and stop it at coordinate $200
Boss_ZLeoUpdateDefeatStageScroll:                       ; was: sub_52A54
                tst.w   (RasterEffectIndex).w
                beq.s   Boss_ZLeoUpdateDefeatStageScrollReturn
                cmpi.w  #$200,(Entity57YPos).w
                bmi.s   Boss_ZLeoAccelerateDefeatStageScroll
                clr.l   $1C(a5)
                move.w  #$200,(Entity57YPos).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoAccelerateDefeatStageScroll:                   ; was: loc_52A76
                addi.l  #$800,(Entity57YVel).w
Boss_ZLeoUpdateDefeatStageScrollReturn:                 ; was: locret_52A7E
                rts
; End of function Boss_ZLeoUpdateDefeatStageScroll
; Interpret the selected pose stream and project its interpolated segment chain
Boss_ZLeoInterpretAndApplyPose:                         ; was: sub_52A80
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_ZLeoAdvancePoseInterpolation
Boss_ZLeoReadPoseCommand:                               ; was: loc_52A8A
                                        ; Boss_ZLeoInterpretAndApplyPose+44   j
                move.w  $58(a5),d0
                bmi.w   Boss_ZLeoApplyInterpolatedSegmentPose
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ZLeoHandlePoseControlWord
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ZLeoReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ZLeoHandlePoseControlWord:                         ; was: loc_52AA6
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_ZLeoHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoHandlePoseLoopCommand:                         ; was: loc_52AB6
                cmpi.w  #$FFFF,d3
                bne.s   Boss_ZLeoBeginPoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ZLeoReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ZLeoBeginPoseInterpolation:                        ; was: loc_52AC6
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_ZLeoPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_ZLeoCalculatePoseChannelDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_ZLeoApplyInterpolatedSegmentPose
Boss_ZLeoAdvancePoseInterpolation:                      ; was: loc_52AF8
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$D,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_ZLeoApplyInterpolatedSegmentPose:                  ; was: loc_52B08
                                        ; Boss_ZLeoInterpretAndApplyPose+76   j
                moveq   #7,d6
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$116(a5)
                moveq   #0,d2
                move.w  8(a0),d2
                swap    d2
                asr.l   d6,d2
                swap    d2
                and.w   d7,d2
                move.w  d2,$176(a5)
                swap    d2
                moveq   #0,d1
                move.w  $C(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d2,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$1D6(a5)
                swap    d1
                moveq   #0,d2
                move.w  $10(a0),d2
                swap    d2
                asr.l   d6,d2
                add.l   d1,d2
                swap    d2
                and.w   d7,d2
                move.w  d2,$236(a5)
                swap    d2
                moveq   #0,d1
                move.w  $14(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d2,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$296(a5)
                moveq   #0,d2
                move.w  $18(a0),d2
                swap    d2
                asr.l   d6,d2
                swap    d2
                and.w   d7,d2
                move.w  d2,$2F6(a5)
                move.w  d2,$356(a5)
                swap    d2
                moveq   #0,d1
                move.w  $1C(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d2,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$3B6(a5)
                move.w  d1,$416(a5)
                swap    d1
                moveq   #0,d2
                move.w  $20(a0),d2
                swap    d2
                asr.l   d6,d2
                add.l   d1,d2
                swap    d2
                and.w   d7,d2
                move.w  d2,$476(a5)
                move.w  d2,$4D6(a5)
                swap    d2
                moveq   #0,d1
                move.w  $24(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d2,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$536(a5)
                move.w  d1,$596(a5)
                swap    d1
                moveq   #0,d2
                move.w  $28(a0),d2
                swap    d2
                asr.l   d6,d2
                add.l   d1,d2
                swap    d2
                and.w   d7,d2
                move.w  d2,$5F6(a5)
                move.b  $2C(a0),d0
                ext.w   d0
                move.w  d0,d1
                add.w   $2FC(a5),d0
                move.w  d0,$10(a5)
                asr.w   #2,d1
                addi.w  #$20,d1                         ; ' '
                move.w  d1,(SecondaryCameraXPos).w
                move.b  $30(a0),d0
                ext.w   d0
                move.w  d0,d1
                add.w   $35C(a5),d0
                move.w  d0,$14(a5)
                tst.b   $47C(a5)
                bne.s   Boss_ZLeoInterpretAndApplyPoseReturn
                asr.w   #2,d1
                move.w  #$20,d0                         ; ' '
                sub.w   d1,d0
                move.w  d0,(SecondaryCameraYPos).w
Boss_ZLeoInterpretAndApplyPoseReturn:                   ; was: locret_52C32
                rts
; End of function Boss_ZLeoInterpretAndApplyPose
; Calculate interpolation deltas for all fourteen Z-Leo pose channels
Boss_ZLeoCalculatePoseChannelDeltas:                    ; was: sub_52C34
                lea     Boss_ZLeoPoseTable(pc),a1
                nop
                moveq   #$D,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_ZLeoCalculatePoseChannelDeltas
; Initializes fourteen Z-Leo pose channels from bytes at a0
Boss_ZLeoInitializePoseChannels:
                moveq   #$D,d7                          ; was: sub_52C4A
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_ZLeoInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_ZLeoIntroDescentPoses: dc.w    $810, $E, $1010, $E, $810, $1C, $1010, $1C, $FFFF  ; was: word_52C56
Boss_ZLeoDefeatPoses:       dc.w    $3030, $62, $C18, $70, $3030, $70, $C18, $62, $FFFF  ; was: word_52C68
                                        ; Boss_ZLeoBeginDefeatSequence+A0   o
Boss_ZLeoBattleEntryPoses:  dc.w    $810, $E, $1010, $E, $810, $1C, $1010, $1C, $FFFF  ; was: word_52C7A
                                        ; Boss_ZLeoRunBattleEntry+48   o
Boss_ZLeoPriorityTransitionPoses:   dc.w    $1818, $2A, $8001, $1010, $38, $2020, $46, $FFFE  ; was: word_52C8C
Boss_ZLeoBattleReadyPose:           dc.w    $218, $46, $278, $54, $FFFF, $2020, $54, $1010, $54, $FFFF  ; was: word_52C9C
Boss_ZLeoIdlePose:                  dc.w    $1020, $7E, $2020, $7E, $1020, $8C, $2020, $8C, $FFFF  ; was: word_52CB0
                                        ; Boss_ZLeoWaitForBossMessage:Boss_ZLeoRenderBossMessageWait   o
Boss_ZLeoOrbRecoveryPose:           dc.w    $1020, $8C, $2020, $8C, $FFFE  ; was: word_52CC2
Boss_ZLeoOrbOpeningPose0:           dc.w    $2830, $9A, $3030, $9A, $8001, $5060, $A8, $4040, $A8, $FFFE  ; was: word_52CCC
Boss_ZLeoOrbOpeningPose1:           dc.w    $2830, $B6, $3030, $B6, $8001, $5060, $C4, $4040, $C4, $FFFE  ; was: word_52CE0
Boss_ZLeoOrbOpeningPose2:           dc.w    $2830, $D2, $3030, $D2, $8001, $5060, $E0, $4040, $E0, $FFFE  ; was: word_52CF4
Boss_ZLeoOrbOpeningPose3:           dc.w    $2830, $EE, $3030, $EE, $8001, $5060, $FC, $4040, $FC, $FFFE  ; was: word_52D08
Boss_ZLeoScrollingLaserEntryPoses:  dc.w    $1218, $10A, $707, $10A, $1014, $118, $1A1A, $118, $340, $126, $8001, $90E, $126, $1A1A, $126, $1818  ; was: word_52D1C
                                        ; Boss_ZLeoRunScrollingLaserEntryPose:Boss_ZLeoRenderScrollingLaserEntryPose   o
                dc.w    $134, $343C, $142, $FFFE
Boss_ZLeoScrollingLaserBurstPoses:  dc.w    $60A, $142, $A0A, $142, $8001, $103, $150, $303, $150, $FFFE  ; was: word_52D44
                                        ; Boss_ZLeoRunScrollingLaserEntryPose+D4   o
Boss_ZLeoRisingThresholdPoses:  dc.w    $404, $15E, $FFFE  ; was: word_52D58
Boss_ZLeoRisingReturnPose:      dc.w    $810, $16C, $3030, $16C, $FFFE  ; was: word_52D5E
                                        ; Boss_ZLeoBeginRisingReturn:Boss_ZLeoRenderPostAttackDelay   o
Boss_ZLeoPoseTable: binclude "data/other/word_52D68.bin"  ; was: word_52D68
Boss_ZLeoPoseTable_End:                                 ; was: word_52D68_End

; Empty entity state handler in main dispatch table
Boss_ZLeoStageScrollControlNoOp:                        ; was: nullsub_8
                rts
; End of function Boss_ZLeoStageScrollControlNoOp
; Advances Z-Leo's vertical scroll coordinate and queues the exposed tilemap row
Boss_ZLeoAdvanceVerticalScrollAndQueueRow:              ; was: sub_52EE4
                                        ; Boss_ZLeoRunScrollingLaserEntryPose:Boss_ZLeoUpdateScrollingAttackFrame   p
                move.l  $41C(a5),d0
                bmi.s   Boss_ZLeoAdvanceNegativeVerticalScroll
                add.l   d0,(SecondaryCameraYPos).w
                move.w  (SecondaryCameraYPos).w,d1
                subi.w  #8,d1
                bmi.s   Boss_ZLeoQueueTilemapRow
                addi.w  #-$1FFF,d1
                bra.s   Boss_ZLeoQueueTilemapRow
; ---------------------------------------------------------------------------
Boss_ZLeoAdvanceNegativeVerticalScroll:                 ; was: loc_52EFE
                add.l   d0,(SecondaryCameraYPos).w
                move.w  (SecondaryCameraYPos).w,d1
                subi.w  #$E8,d1
                cmpi.w  #$E001,d1
                bpl.s   Boss_ZLeoQueueTilemapRow
                subi.w  #$E000,d1
Boss_ZLeoQueueTilemapRow:                               ; was: loc_52F14
                                        ; Boss_ZLeoAdvanceVerticalScrollAndQueueRow+18   j
                lea     Boss_ZLeoTilemapRowDescriptor(pc),a0
                nop
                moveq   #0,d0
                jmp     Tilemap_QueueRowFromDescriptor
; End of function Boss_ZLeoAdvanceVerticalScrollAndQueueRow
; ---------------------------------------------------------------------------
Boss_ZLeoTilemapRowDescriptor:  dc.w    $FFFF, $7000, $FFFF, $6800, $FFFF, $4000, 0, $6000  ; was: word_52F22
