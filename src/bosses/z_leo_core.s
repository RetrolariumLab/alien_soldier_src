; Advance palette fades, run the selected state, and clear the per-frame projectile flag
Boss_ZLeoMain:                                          ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_51AD6
                tst.w   4(a5)
                beq.w   Boss_ZLeoDispatchStateAndClearProjectileFlag
                tst.w   8(a5)
                beq.w   Boss_ZLeoDispatchStateAndClearProjectileFlag
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_ZLeoUpdateFirstPaletteFade
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_ZLeoUpdateFirstPaletteFade
                tst.w   (BossHealth).w
                beq.w   Boss_ZLeoBeginDefeatSequence
Boss_ZLeoUpdateFirstPaletteFade:                        ; CODE XREF: Boss_ZLeoMain+16   j  ; was: loc_51AFE
                                        ; Boss_ZLeoMain+1E   j
                move.w  $4DC(a5),d0
                beq.s   Boss_ZLeoUpdateSecondPaletteFade
                bpl.s   Boss_ZLeoDecreaseFirstPaletteFade
                addq.w  #1,d0
                bra.s   Boss_ZLeoApplyFirstPaletteFade
; ---------------------------------------------------------------------------
Boss_ZLeoDecreaseFirstPaletteFade:                      ; CODE XREF: Boss_ZLeoMain+2E   j  ; was: loc_51B0A
                subq.w  #1,d0
Boss_ZLeoApplyFirstPaletteFade:                         ; CODE XREF: Boss_ZLeoMain+32   j  ; was: loc_51B0C
                move.w  d0,$4DC(a5)
                movea.w #(PaletteActiveColor01-M68K_RAM),a0
                moveq   #$E,d5
                move.w  $4DE(a5),d7
                jsr     (Gfx_ApplyPaletteFade).l
Boss_ZLeoUpdateSecondPaletteFade:                       ; CODE XREF: Boss_ZLeoMain+2C   j  ; was: loc_51B20
                move.w  $53C(a5),d0
                beq.s   Boss_ZLeoUpdateThirdPaletteFade
                bpl.s   Boss_ZLeoDecreaseSecondPaletteFade
                addq.w  #1,d0
                bra.s   Boss_ZLeoApplySecondPaletteFade
; ---------------------------------------------------------------------------
Boss_ZLeoDecreaseSecondPaletteFade:                     ; CODE XREF: Boss_ZLeoMain+50   j  ; was: loc_51B2C
                subq.w  #1,d0
Boss_ZLeoApplySecondPaletteFade:                        ; CODE XREF: Boss_ZLeoMain+54   j  ; was: loc_51B2E
                move.w  d0,$53C(a5)
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                moveq   #$1E,d5
                move.w  $53E(a5),d7
                jsr     (Gfx_ApplyPaletteFade).l
Boss_ZLeoUpdateThirdPaletteFade:                        ; CODE XREF: Boss_ZLeoMain+4E   j  ; was: loc_51B42
                move.w  $59C(a5),d0
                beq.s   Boss_ZLeoFinalizePaletteFades
                bpl.s   Boss_ZLeoDecreaseThirdPaletteFade
                addq.w  #1,d0
                bra.s   Boss_ZLeoApplyThirdPaletteFade
; ---------------------------------------------------------------------------
Boss_ZLeoDecreaseThirdPaletteFade:                      ; CODE XREF: Boss_ZLeoMain+72   j  ; was: loc_51B4E
                subq.w  #1,d0
Boss_ZLeoApplyThirdPaletteFade:                         ; CODE XREF: Boss_ZLeoMain+76   j  ; was: loc_51B50
                move.w  d0,$59C(a5)
                movea.w #(PaletteActiveColor49-M68K_RAM),a0
                moveq   #$E,d5
                move.w  $59E(a5),d7
                jsr     (Gfx_ApplyPaletteFade).l
Boss_ZLeoFinalizePaletteFades:                          ; CODE XREF: Boss_ZLeoMain+70   j  ; was: loc_51B64
                jsr     (Gfx_ProcessDefaultColorFade).l
Boss_ZLeoDispatchStateAndClearProjectileFlag:           ; CODE XREF: Boss_ZLeoMain+4   j  ; was: loc_51B6A
                                        ; Boss_ZLeoMain+C   j
                bsr.s   Boss_ZLeoDispatcher
                clr.w   (ZLeoDropProjectileFlag).w
                rts
; End of function Boss_ZLeoMain
; Dispatch the even-valued state through the ROM-ordered state table
Boss_ZLeoDispatcher:                                    ; CODE XREF: Boss_ZLeoMain:Boss_ZLeoDispatchStateAndClearProjectileFlag   p  ; was: sub_51B72
                move.w  4(a5),d0
                movea.w Boss_ZLeoStateTable(pc,d0.w),a0
                adda.l  #Boss_ZLeoNoOp,a0
                jmp     (a0)
; End of function Boss_ZLeoDispatcher
; ---------------------------------------------------------------------------
Boss_ZLeoStateTable:    dc.w    Boss_ZLeoInit-Boss_ZLeoNoOp  ; was: off_51B82
                                        ; DATA XREF: Boss_ZLeoDispatcher+4   r
                dc.w    Boss_ZLeoIntroInit-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunIntroDescent-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunDefeatTransition-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunDefeatFade-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunDefeatWhiteout-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunPostDefeatDelay-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoPostDefeatNoOp-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunIntroCountdown-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunBattleEntry-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoWaitForBattlePose-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunBattlePose-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunBattleReadyPose-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunBossMessageDelay-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoWaitForBossMessage-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoSelectAttackState-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoWaitForOrbAttackCue-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunOrbEmission-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunOrbRecovery-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoWaitForScrollingLaserCue-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunScrollingLaserEntryPose-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunScrollingLaserBurst-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunScrollAcceleration-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunScrollCruise-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunScrollReversal-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunDropAttackHold-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunRisingReturn-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunPostAttackDelay-Boss_ZLeoNoOp
                dc.w    Boss_ZLeoRunLaserOpeningDelay-Boss_ZLeoNoOp

Boss_ZLeoNoOp:                                          ; CODE XREF: Boss_ZLeoIntroInit+E   j  ; was: nullsub_120
                                        ; Boss_ZLeoStreamTileChunkForCameraY+16   j
                rts
; End of function Boss_ZLeoNoOp

; Wait for the stage gate, prepare graphics, and advance to composite-part initialization
Boss_ZLeoInit:                                          ; DATA XREF: ROM:Boss_ZLeoStateTable   o  ; was: sub_51BBE
                tst.w   (MessageSequenceState).w
                bne.w   Boss_ZLeoInitReturn
                addq.w  #2,4(a5)
                bset    #0,(PlayerRestrictionFlags).w
                move.w  #$3F8,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$54,(RasterEffectIndex).w      ; 'T'
                clr.w   (RasterEffectInitState).w
                move.w  #$18,(RasterLayoutOffset).w
                bset    #7,(CameraMotionLockFlags).w
                bset    #6,(CameraMotionLockFlags).w
                movea.l #(LargeTilemapBuffer+$520),a0
                move.w  #$A000,d0
                moveq   #5,d7
                jsr     (Gfx_AdjustTileIndexRows).l
                bsr.w   Boss_ZLeoInitializeStageScrollControlObject
                bsr.w   Boss_ZLeoBuildHBlankRegisterBuffer
                bsr.w   Boss_ZLeoLoadInitialTilesAndSetCommand81
                move.l  #Gfx_TitleAndZLeoVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                move.w  #$F600,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
Boss_ZLeoInitReturn:                                    ; CODE XREF: Boss_ZLeoInit+4   j  ; was: locret_51C30
                rts
; End of function Boss_ZLeoInit
; Initialize the composite parts, mappings, and intro display state
Boss_ZLeoIntroInit:                                     ; DATA XREF: ROM:00051B84   o  ; was: sub_51C32
                bsr.w   Boss_ZLeoBuildHBlankRegisterBuffer
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.w   Boss_ZLeoNoOp
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$380,(MetaspriteBaseTileWord).w
                moveq   #$F,d7
                movea.l #Boss_ZLeoValkirieForceSharedMetaspriteData,a0
                movea.l #Boss_ZLeoPartRadii,a1
                movea.l #Boss_ZLeoPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$3F8,(a5)
                move.w  #$C00,2(a5)
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$6000,d0
                move.w  #$280,d1
                moveq   #$1F,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                movea.l #ZLeoPriorityFirstRow,a0
                move.w  #$E000,d0
                moveq   #3,d7
                jsr     (Gfx_AdjustTileIndexRows).l
                move.w  #$7FFF,d0
                lea     (ZLeoPriorityFirstRow).l,a0
                and.w   d0,(a0)
                and.w   d0,2(a0)
                and.w   d0,8(a0)
                and.w   d0,$A(a0)
                and.w   d0,$10(a0)
                and.w   d0,$12(a0)
                and.w   d0,$18(a0)
                and.w   d0,$1A(a0)
                lea     (ZLeoPriorityLastRow).l,a0
                and.w   d0,ZLeoPriorityLastCol2-ZLeoPriorityLastRow(a0)
                and.w   d0,6(a0)
                and.w   d0,$C(a0)
                and.w   d0,$E(a0)
                and.w   d0,$14(a0)
                and.w   d0,$16(a0)
                and.w   d0,$1C(a0)
                and.w   d0,$1E(a0)
                clr.w   (ZLeoTileScrollIndex).w
                clr.w   (PrimaryCameraXPosition).w
                move.w  #$100,(PrimaryCameraYPosition).w
                move.w  #$100,(ZLeoPreviousCameraY).w
                bset    #7,(CameraMotionLockFlags).w
                bset    #6,(CameraMotionLockFlags).w
                move.w  #$10,d0
                move.w  #$C000,d1
                move.w  #$4B80,d2
                movea.w #(TwentyFirstEntityType-M68K_RAM),a0
                moveq   #2,d7
Boss_ZLeoInitializeIntroPartRows:                       ; CODE XREF: Boss_ZLeoIntroInit+110   j  ; was: loc_51D1E
                moveq   #$10,d3
                moveq   #2,d6
Boss_ZLeoInitializeIntroPartRow:                        ; CODE XREF: Boss_ZLeoIntroInit+10C   j  ; was: loc_51D22
                move.w  d0,(a0)
                move.w  d1,2(a0)
                move.w  d2,$E(a0)
                move.b  d3,$20(a0)
                subq.w  #4,d3
                move.l  #Boss_ZLeoIntroPartRowMapping,8(a0)
                lea     $60(a0),a0
                dbf     d6,Boss_ZLeoInitializeIntroPartRow
                dbf     d7,Boss_ZLeoInitializeIntroPartRows
                move.l  #Boss_ZLeoIntroLowerPartMapping,d4
                move.l  d4,$848(a5)
                move.l  d4,$968(a5)
                move.l  d4,$A88(a5)
                movea.w #(ThirtiethEntityType-M68K_RAM),a0
                moveq   #$50,d3                         ; 'P'
                moveq   #5,d7
Boss_ZLeoInitializeLowerIntroParts:                     ; CODE XREF: Boss_ZLeoIntroInit+140   j  ; was: loc_51D60
                move.w  d0,(a0)
                move.w  d1,2(a0)
                move.w  d2,$E(a0)
                move.b  d3,$20(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ZLeoInitializeLowerIntroParts
                move.l  #Boss_ZLeoIntroOuterPartMapping,$AE8(a5)
                move.l  #Boss_ZLeoIntroSidePartMapping,$B48(a5)
                move.l  #Boss_ZLeoIntroFarSidePartMapping,$BA8(a5)
                move.l  #Boss_ZLeoIntroOuterPartMapping,$C08(a5)
                move.l  #Boss_ZLeoIntroSidePartMapping,$C68(a5)
                move.l  #Boss_ZLeoIntroFarSidePartMapping,$CC8(a5)
                bclr    #3,$AEE(a5)
                bclr    #3,$B4E(a5)
                bclr    #3,$BAE(a5)
                move.b  #$4C,$B60(a5)                   ; 'L'
                move.b  #$4C,$C80(a5)                   ; 'L'
                movea.l #Boss_ZLeoObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                clr.l   $2FC(a5)
                clr.l   $35C(a5)
                move.w  #2,$1DE(a5)
                bra.w   Boss_ZLeoPrepareIntroMovement
; End of function Boss_ZLeoIntroInit
; Prepare the intro descent from $1A0 to $E8
Boss_ZLeoPrepareIntroDescent:                           ; was: sub_51DE2
                move.w  #$120,$2FC(a5)
                move.w  #$1A0,$35C(a5)
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; Lower the selected composite position until it reaches $E8
Boss_ZLeoRunIntroDescent:                               ; DATA XREF: ROM:00051B86   o  ; was: loc_51E0E
                subq.w  #1,$35C(a5)
                cmpi.w  #$E8,$35C(a5)
                bpl.s   Boss_ZLeoUpdateIntroDescentPose
                move.w  #$E8,$35C(a5)
                clr.b   (BossColorEffectFlags).w
Boss_ZLeoUpdateIntroDescentPose:                        ; CODE XREF: Boss_ZLeoPrepareIntroDescent+36   j  ; was: loc_51E24
                move.w  $5B4(a5),d0
                addi.w  #0,d0
                move.w  d0,(Entity57YPos).w
                lea     Boss_ZLeoIntroDescentPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; End of function Boss_ZLeoPrepareIntroDescent
; Unreferenced controller entry for adjusting position and the shared scroll coordinate
Debug_ZLeoPositionAndStartIntro:                        ; was: sub_51E3A
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_ZLeoCheckMoveRightInput
                subq.w  #3,$10(a5)
Debug_ZLeoCheckMoveRightInput:                          ; CODE XREF: Debug_ZLeoPositionAndStartIntro+6   j  ; was: loc_51E46
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_ZLeoCheckMoveUpInput
                addq.w  #3,$10(a5)
Debug_ZLeoCheckMoveUpInput:                             ; CODE XREF: Debug_ZLeoPositionAndStartIntro+12   j  ; was: loc_51E52
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_ZLeoCheckMoveDownInput
                subq.w  #2,$14(a5)
Debug_ZLeoCheckMoveDownInput:                           ; CODE XREF: Debug_ZLeoPositionAndStartIntro+1E   j  ; was: loc_51E5E
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_ZLeoCheckIncreaseScrollInput
                addq.w  #2,$14(a5)
Debug_ZLeoCheckIncreaseScrollInput:                     ; CODE XREF: Debug_ZLeoPositionAndStartIntro+2A   j  ; was: loc_51E6A
                btst    #6,(ControllerHeldState).w
                beq.s   Debug_ZLeoCheckDecreaseScrollInput
                addq.w  #2,(Entity57YPos).w
Debug_ZLeoCheckDecreaseScrollInput:                     ; CODE XREF: Debug_ZLeoPositionAndStartIntro+36   j  ; was: loc_51E76
                btst    #4,(ControllerHeldState).w
                beq.s   Boss_ZLeoPrepareIntroMovement
                subq.w  #2,(Entity57YPos).w
Boss_ZLeoPrepareIntroMovement:                          ; CODE XREF: Boss_ZLeoIntroInit+1AC   j  ; was: loc_51E82
                                        ; Debug_ZLeoPositionAndStartIntro+42   j
                move.w  #$10,4(a5)
                move.w  #$1C0,$11C(a5)
                move.w  #$120,$2FC(a5)
                move.w  #$1E0,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.b  #$95,d0
                jsr     (Sound_QueueBGMRequest).l
; End of function Debug_ZLeoPositionAndStartIntro
; Count down the intro hold, play its cue, and hand off to battle entry
Boss_ZLeoRunIntroCountdown:                             ; DATA XREF: ROM:00051B92   o  ; was: sub_51EB6
                cmpi.w  #$1B8,$11C(a5)
                bne.s   Boss_ZLeoAdvanceIntroCountdown
                move.b  #$F7,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_ZLeoAdvanceIntroCountdown:                         ; CODE XREF: Boss_ZLeoRunIntroCountdown+6   j  ; was: loc_51EC8
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginBattleEntry
                move.w  #2,(PlaneBShakeLevel).w
                lea     Boss_ZLeoBattleEntryPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginBattleEntry:                              ; CODE XREF: Boss_ZLeoRunIntroCountdown+16   j  ; was: loc_51EDE
                addq.w  #2,4(a5)
                move.w  #$E000,$59E(a5)
                move.w  #$FFF6,$11C(a5)
                clr.w   $11E(a5)
                lea     Boss_ZLeoBattleEntryEffectDescriptor(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
; End of function Boss_ZLeoRunIntroCountdown
; Move the composite coordinate toward $F0 while pulsing the entry fade
Boss_ZLeoRunBattleEntry:                                ; DATA XREF: ROM:00051B94   o  ; was: sub_51EFE
                subi.l  #$8000,$35C(a5)
                cmpi.w  #$F0,$35C(a5)
                bmi.s   Boss_ZLeoFinishBattleEntry
                tst.w   $11E(a5)
                bne.s   Boss_ZLeoPulseBattleEntryFade
                cmpi.w  #$144,$35C(a5)
                bpl.s   Boss_ZLeoRenderBattleEntry
                addq.w  #1,$11E(a5)
Boss_ZLeoPulseBattleEntryFade:                          ; CODE XREF: Boss_ZLeoRunBattleEntry+14   j  ; was: loc_51F20
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_ZLeoRenderBattleEntry
                addq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoRenderBattleEntry
                clr.w   $11C(a5)
Boss_ZLeoRenderBattleEntry:                             ; CODE XREF: Boss_ZLeoRunBattleEntry+1C   j  ; was: loc_51F34
                                        ; Boss_ZLeoRunBattleEntry+2A   j
                move.w  $11C(a5),$59C(a5)
                move.w  #3,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
                lea     Boss_ZLeoBattleEntryPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBattleEntryEffectDescriptor:   dc.w    6       ; field_0  ; was: stru_51F50
                                        ; DATA XREF: Boss_ZLeoRunIntroCountdown+3C   o
                dc.l    Stage25ZLeoEntryMappingData2020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    $FFFF
; ---------------------------------------------------------------------------
Boss_ZLeoFinishBattleEntry:                             ; CODE XREF: Boss_ZLeoRunBattleEntry+E   j  ; was: loc_51F5A
                addq.w  #2,4(a5)
                move.w  #$F0,$35C(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
; Hold the entry pose before enabling its animated parts
Boss_ZLeoWaitForBattlePose:                             ; DATA XREF: ROM:00051B96   o  ; was: loc_51F76
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginBattlePose
                lea     Boss_ZLeoBattleEntryPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginBattlePose:                               ; CODE XREF: Boss_ZLeoRunBattleEntry+7C   j  ; was: loc_51F86
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                bsr.w   Boss_ZLeoLoadPrimaryTiles
; End of function Boss_ZLeoRunBattleEntry
; Run the battle pose and respond to its sprite-priority event
Boss_ZLeoRunBattlePose:                                 ; DATA XREF: ROM:00051B98   o  ; was: sub_51FAA
                tst.w   $58(a5)
                bmi.s   Boss_ZLeoBeginBattleReadySequence
                bclr    #0,$23E(a5)
                beq.s   Boss_ZLeoRenderBattlePose
                bsr.w   Boss_ZLeoSetSixPartsHighPriority
Boss_ZLeoRenderBattlePose:                              ; CODE XREF: Boss_ZLeoRunBattlePose+C   j  ; was: loc_51FBC
                lea     Boss_ZLeoPriorityTransitionPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginBattleReadySequence:                      ; CODE XREF: Boss_ZLeoRunBattlePose+4   j  ; was: loc_51FC6
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$60,$11C(a5)                   ; '`'
                bsr.w   Boss_ZLeoLoadPhaseTiles
                move.b  #$EC,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_ZLeoRunBattlePose
; Run the timed battle-ready pose
Boss_ZLeoRunBattleReadyPose:                            ; DATA XREF: ROM:00051B9A   o  ; was: sub_51FE8
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginBossMessageDelay
                lea     Boss_ZLeoBattleReadyPose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoBeginBossMessageDelay:                         ; CODE XREF: Boss_ZLeoRunBattleReadyPose+4   j  ; was: loc_51FF8
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; Hold the final pose before starting the boss message
Boss_ZLeoRunBossMessageDelay:                           ; DATA XREF: ROM:00051B9C   o  ; was: loc_5200C
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoStartBossMessage
                lea     Boss_ZLeoIdlePose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoStartBossMessage:                              ; CODE XREF: Boss_ZLeoRunBattleReadyPose+28   j  ; was: loc_5201C
                addq.w  #2,4(a5)
                moveq   #0,d0
                jsr     (BossMessage_Start).l
; End of function Boss_ZLeoRunBattleReadyPose
; Wait for the boss-message gate before entering the first attack-cycle state
Boss_ZLeoWaitForBossMessage:                            ; DATA XREF: ROM:00051B9E   o  ; was: sub_52028
                tst.w   (MessageSequenceState).w
                bne.s   Boss_ZLeoRenderBossMessageWait
                move.w  #$1E,4(a5)
                clr.b   (BossColorEffectFlags).w
                bra.w   Boss_ZLeoSelectAttackState
; ---------------------------------------------------------------------------
Boss_ZLeoRenderBossMessageWait:                         ; CODE XREF: Boss_ZLeoWaitForBossMessage+4   j  ; was: loc_5203C
                lea     Boss_ZLeoIdlePose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; End of function Boss_ZLeoWaitForBossMessage
; Enter the health-zero defeat sequence and initialize its transition
Boss_ZLeoBeginDefeatSequence:                           ; CODE XREF: Boss_ZLeoMain+24   j  ; was: sub_52046
                move.w  #6,4(a5)
                move.b  #$40,(GameplayControlFlags).w   ; '@'
                move.w  #8,(StageSpawnCountdown).w
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,(StageTimerPauseFlag).w
                clr.b   $21(a5)
                move.w  #$34,(PlayerScriptStateOffset).w  ; '4'
                bset    #2,(Entity57Flags).w
                move.l  #$FFFF0000,(Entity57YVel).w
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$C0,$11C(a5)
                bsr.w   Boss_ZLeoLoadPrimaryTiles
                move.b  #1,(SoundFadeOutDelay).w
; Run the initial defeat transition
Boss_ZLeoRunDefeatTransition:                           ; DATA XREF: ROM:00051B88   o  ; was: loc_52096
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginDefeatFade
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bsr.w   Boss_ZLeoSpawnDefeatEffect
                bsr.w   Boss_ZLeoUpdateDefeatStageScroll
                lea     Boss_ZLeoDefeatPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginDefeatFade:                               ; CODE XREF: Boss_ZLeoBeginDefeatSequence+54   j  ; was: loc_520C0
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
; Advance the defeat fade before whiteout
Boss_ZLeoRunDefeatFade:                                 ; DATA XREF: ROM:00051B8A   o  ; was: loc_520C8
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_ZLeoUpdateDefeatFade
                addq.w  #1,$11C(a5)
                cmpi.w  #8,$11C(a5)
                beq.s   Boss_ZLeoBeginDefeatWhiteout
Boss_ZLeoUpdateDefeatFade:                              ; CODE XREF: Boss_ZLeoBeginDefeatSequence+8A   j  ; was: loc_520DE
                bsr.w   Boss_ZLeoUpdateDefeatPaletteFadeAndShake
                bsr.w   Boss_ZLeoSpawnDefeatEffect
                lea     Boss_ZLeoDefeatPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginDefeatWhiteout:                           ; CODE XREF: Boss_ZLeoBeginDefeatSequence+96   j  ; was: loc_520F0
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                movea.w #(Entity58Type-M68K_RAM),a0
                move.w  #$354,(a0)
                clr.w   4(a0)
                move.w  #$120,$10(a0)
                move.w  #$F0,$14(a0)
                movea.l #ZLeoPriorityFirstRow,a0
                move.w  #$6000,d0
                moveq   #3,d7
                jsr     (Gfx_AdjustTileIndexRows).l
                lea     Boss_ZLeoDefeatTileLoadDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                move.b  #$14,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_ZLeoBeginDefeatSequence
; Advance defeat whiteout, clear objects, and fill both palette banks with white
Boss_ZLeoRunDefeatWhiteout:                             ; DATA XREF: ROM:00051B8C   o  ; was: sub_52138
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_ZLeoUpdateDefeatWhiteoutFade
                addq.w  #1,$11C(a5)
                cmpi.w  #$11,$11C(a5)
                beq.s   Boss_ZLeoFinishDefeatWhiteout
Boss_ZLeoUpdateDefeatWhiteoutFade:                      ; CODE XREF: Boss_ZLeoRunDefeatWhiteout+8   j  ; was: loc_5214E
                bsr.w   Boss_ZLeoUpdateDefeatPaletteFadeAndShake
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoDefeatTileLoadDescriptor:  dc.w    $4618, $2000, $300, $405, $607  ; was: word_52154
                                        ; DATA XREF: Boss_ZLeoBeginDefeatSequence+DC   o
; ---------------------------------------------------------------------------
Boss_ZLeoFinishDefeatWhiteout:                          ; CODE XREF: Boss_ZLeoRunDefeatWhiteout+14   j  ; was: loc_5215E
                addq.w  #2,4(a5)
                clr.w   8(a5)
                move.w  #$120,$48(a5)
                move.w  #$3F8,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                movea.w #(PaletteShadowBuffer-M68K_RAM),a0
                move.w  #$EEE,d0
                moveq   #$3F,d7                         ; '?'
Boss_ZLeoFillDefeatWhitePalettes:                       ; CODE XREF: Boss_ZLeoRunDefeatWhiteout+50   j  ; was: loc_52182
                move.w  d0,-$80(a0)
                move.w  d0,(a0)+
                dbf     d7,Boss_ZLeoFillDefeatWhitePalettes
; End of function Boss_ZLeoRunDefeatWhiteout
; Wait after defeat, then restore the shared UI and weapon display state
Boss_ZLeoRunPostDefeatDelay:                            ; DATA XREF: ROM:00051B8E   o  ; was: sub_5218C
                subq.w  #1,$48(a5)
                bmi.s   Boss_ZLeoRestorePostDefeatUi
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoRestorePostDefeatUi:                           ; CODE XREF: Boss_ZLeoRunPostDefeatDelay+4   j  ; was: loc_52194
                addq.w  #2,4(a5)
                move.w  #$8002,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.b  #$80,(GameplayControlFlags).w
                move.w  #2,(SetupTransitionIndex).w
                move.w  #4,(GameplayExitMode).w
                jmp     Results_StoreStageCompletionTime
; End of function Boss_ZLeoRunPostDefeatDelay
; Inert post-defeat state
Boss_ZLeoPostDefeatNoOp:                                ; DATA XREF: ROM:00051B90   o  ; was: nullsub_121
                rts
; End of function Boss_ZLeoPostDefeatNoOp
; Reset the shared pose state before returning to attack selection
Boss_ZLeoBeginAttackSelection:                          ; CODE XREF: Boss_ZLeoWaitForOrbAttackCue+5E   j  ; was: sub_521C2
                                        ; Boss_ZLeoBeginRisingReturn+C6   j
                move.w  #$1E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.b   $47C(a5)
; Select an opening from health thresholds and frame-derived random bits
Boss_ZLeoSelectAttackState:                             ; CODE XREF: Boss_ZLeoWaitForBossMessage+10   j  ; was: loc_521D6
                                        ; DATA XREF: ROM:00051BA0   o
                subq.w  #1,$11C(a5)
                bpl.s   Boss_ZLeoRenderAttackSelectionWait
                cmpi.w  #$4200,(BossHealth).w
                bpl.s   Boss_ZLeoSelectLaserOpening
                moveq   #3,d1
                cmpi.w  #$2500,(BossHealth).w
                bpl.s   Boss_ZLeoApplyLowHealthRandomMask
                moveq   #1,d1
Boss_ZLeoApplyLowHealthRandomMask:                      ; CODE XREF: Boss_ZLeoBeginAttackSelection+2A   j  ; was: loc_521F0
                move.w  (RandomNumberState).w,d0
                and.w   d1,d0
                beq.s   Boss_ZLeoSelectAlternateOpening
Boss_ZLeoSelectLaserOpening:                            ; CODE XREF: Boss_ZLeoBeginAttackSelection+20   j  ; was: loc_521F8
                bra.w   Boss_ZLeoBeginLaserOpening
; ---------------------------------------------------------------------------
Boss_ZLeoSelectAlternateOpening:                        ; CODE XREF: Boss_ZLeoBeginAttackSelection+34   j  ; was: loc_521FC
                bra.w   Boss_ZLeoBeginScrollingLaserAttack
; ---------------------------------------------------------------------------
Boss_ZLeoRenderAttackSelectionWait:                     ; CODE XREF: Boss_ZLeoBeginAttackSelection+18   j  ; was: loc_52200
                lea     Boss_ZLeoIdlePose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoBeginLaserOpening:                             ; CODE XREF: Boss_ZLeoBeginAttackSelection:Boss_ZLeoSelectLaserOpening   j  ; was: loc_5220A
                move.w  #$38,4(a5)                      ; '8'
                bsr.w   Boss_ZLeoLoadPrimaryTiles
                move.w  #$80,$11C(a5)
                bsr.w   Boss_ZLeoSpawnExpandingOrbitLaser
                move.w  #4,$B28(a5)
                move.w  #4,$C48(a5)
; Hold the laser opening, swap phase tiles, and select its pose table
Boss_ZLeoRunLaserOpeningDelay:                          ; DATA XREF: ROM:00051BBA   o  ; was: loc_5222A
                cmpi.w  #$60,$11C(a5)                   ; '`'
                bne.s   Boss_ZLeoAdvanceLaserOpeningDelay
                bsr.w   Boss_ZLeoLoadPhaseTiles
Boss_ZLeoAdvanceLaserOpeningDelay:                      ; CODE XREF: Boss_ZLeoBeginAttackSelection+6E   j  ; was: loc_52236
                subq.w  #1,$11C(a5)
                bpl.s   Boss_ZLeoRenderLaserOpeningDelay
                move.w  (RandomNumberState).w,d0
                andi.w  #$C,d0
                move.w  d0,$47E(a5)
                move.l  Boss_ZLeoOpeningPoseTable(pc,d0.w),$3BC(a5)
                bra.w   Boss_ZLeoBeginOrbAttackPose
; ---------------------------------------------------------------------------
Boss_ZLeoRenderLaserOpeningDelay:                       ; CODE XREF: Boss_ZLeoBeginAttackSelection+78   j  ; was: loc_52252
                lea     Boss_ZLeoIdlePose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoOpeningPoseTable:  dc.l    Boss_ZLeoOrbOpeningPose0  ; DATA XREF: Boss_ZLeoBeginAttackSelection+86   r  ; was: off_5225C
                dc.l    Boss_ZLeoOrbOpeningPose1
                dc.l    Boss_ZLeoOrbOpeningPose2
                dc.l    Boss_ZLeoOrbOpeningPose3
; ---------------------------------------------------------------------------
Boss_ZLeoBeginOrbAttackPose:                            ; CODE XREF: Boss_ZLeoBeginAttackSelection+8C   j  ; was: loc_5226C
                move.w  #$20,4(a5)                      ; ' '
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.b   $23E(a5)
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_ZLeoBeginAttackSelection
; Wait for the pose-stream event that opens the orb-emission interval
Boss_ZLeoWaitForOrbAttackCue:                           ; DATA XREF: ROM:00051BA2   o  ; was: sub_5228A
                bclr    #0,$23E(a5)
                bne.s   Boss_ZLeoBeginOrbEmission
                movea.l $3BC(a5),a1
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoBeginOrbEmission:                              ; CODE XREF: Boss_ZLeoWaitForOrbAttackCue+6   j  ; was: loc_5229A
                addq.w  #2,4(a5)
; Emit orbs until the selected opening pose reaches its terminal command
Boss_ZLeoRunOrbEmission:                                ; DATA XREF: ROM:00051BA4   o  ; was: loc_5229E
                tst.w   $58(a5)
                bmi.s   Boss_ZLeoBeginOrbRecovery
                bsr.w   Boss_ZLeoSpawnOrb
                movea.l $3BC(a5),a1
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoBeginOrbRecovery:                              ; CODE XREF: Boss_ZLeoWaitForOrbAttackCue+18   j  ; was: loc_522B0
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$11C(a5)
; Play the recovery pose, then return to the attack selector
Boss_ZLeoRunOrbRecovery:                                ; DATA XREF: ROM:00051BA6   o  ; was: loc_522C4
                subq.w  #1,$11C(a5)
                bne.s   Boss_ZLeoCheckOrbRecoveryComplete
                cmpi.w  #8,$47E(a5)
                bne.s   Boss_ZLeoCheckOrbRecoveryComplete
                move.b  #$3A,d0                         ; ':'
                jsr     (Sound_QueueSFXRequest).l
Boss_ZLeoCheckOrbRecoveryComplete:                      ; CODE XREF: Boss_ZLeoWaitForOrbAttackCue+3E   j  ; was: loc_522DC
                                        ; Boss_ZLeoWaitForOrbAttackCue+46   j
                tst.w   $58(a5)
                bpl.s   Boss_ZLeoRenderOrbRecovery
                move.w  #$40,$11C(a5)                   ; '@'
                bra.w   Boss_ZLeoBeginAttackSelection
; ---------------------------------------------------------------------------
Boss_ZLeoRenderOrbRecovery:                             ; CODE XREF: Boss_ZLeoWaitForOrbAttackCue+56   j  ; was: loc_522EC
                lea     Boss_ZLeoOrbRecoveryPose(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; End of function Boss_ZLeoWaitForOrbAttackCue
; Prepare the pose and shared flags for the scrolling laser branch
Boss_ZLeoBeginScrollingLaserAttack:                     ; CODE XREF: Boss_ZLeoBeginAttackSelection:Boss_ZLeoSelectAlternateOpening   j  ; was: sub_522F6
                move.w  #$26,4(a5)                      ; '&'
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.b   $23E(a5)
                bset    #1,(BossColorEffectFlags).w
                clr.b   $21(a5)
                bset    #0,(StageTimerPauseFlag).w
; Wait for the entry pose to signal the start of stage scrolling
Boss_ZLeoWaitForScrollingLaserCue:                      ; DATA XREF: ROM:00051BA8   o  ; was: loc_5231A
                bclr    #0,$23E(a5)
                bne.s   Boss_ZLeoStartScrollingLaserAttack
                lea     Boss_ZLeoScrollingLaserEntryPoses(pc),a1
                nop
                bra.w   Boss_ZLeoSyncStageCoordinateAndRender
; ---------------------------------------------------------------------------
Boss_ZLeoStartScrollingLaserAttack:                     ; CODE XREF: Boss_ZLeoBeginScrollingLaserAttack+2A   j  ; was: loc_5232C
                addq.w  #2,4(a5)
                bset    #2,(PlayerRestrictionFlags).w
                bset    #2,(Entity57Flags).w
                move.l  #$FFF00000,(Entity57YVel).w
                move.b  #$4F,d0                         ; 'O'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_ZLeoLoadPrimaryTiles
                move.w  #$E000,$59E(a5)
                move.w  #$FFF8,$59C(a5)
                move.b  #$13,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_ZLeoBeginScrollingLaserAttack
; Run the scrolling attack's entry pose and stop its initial velocity at the threshold
Boss_ZLeoRunScrollingLaserEntryPose:                    ; DATA XREF: ROM:00051BAA   o  ; was: sub_52368
                tst.w   $58(a5)
                bmi.s   Boss_ZLeoBeginScrollingLaserBurst
                cmpi.w  #$40,(Entity57YPos).w           ; '@'
                bpl.s   Boss_ZLeoRenderScrollingLaserEntryPose
                move.w  #$34,(PlayerScriptStateOffset).w  ; '4'
                move.w  (Entity57YPos).w,d0
                subi.w  #$20,d0                         ; ' '
                move.w  d0,(PlayerYPosition).w
                clr.l   (Entity57YVel).w
Boss_ZLeoRenderScrollingLaserEntryPose:                 ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+C   j  ; was: loc_5238C
                lea     Boss_ZLeoScrollingLaserEntryPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginScrollingLaserBurst:                      ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+4   j  ; was: loc_52396
                addq.w  #2,4(a5)
                move.w  #3,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Repeat the event-bearing pose and spawn four laser pairs
Boss_ZLeoRunScrollingLaserBurst:                        ; DATA XREF: ROM:00051BAC   o  ; was: loc_523AA
                bclr    #0,$23E(a5)
                beq.s   Boss_ZLeoLoopScrollingLaserBurstPose
                movea.w #(ThirtiethEntityType-M68K_RAM),a4
                btst    #0,$11D(a5)
                bne.s   Boss_ZLeoSpawnScrollingLaserPair
                movea.w #(ThirtyThirdEntityType-M68K_RAM),a4
Boss_ZLeoSpawnScrollingLaserPair:                       ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+54   j  ; was: loc_523C2
                move.w  #9,$48(a4)
                bsr.w   Boss_ZLeoCreateScrollingLaserPair
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginScrollAcceleration
Boss_ZLeoLoopScrollingLaserBurstPose:                   ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+48   j  ; was: loc_523D2
                tst.w   $58(a5)
                bpl.s   Boss_ZLeoRenderScrollingLaserBurstPose
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_ZLeoRenderScrollingLaserBurstPose:                 ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+6E   j  ; was: loc_523E2
                lea     Boss_ZLeoScrollingLaserBurstPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginScrollAcceleration:                       ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+68   j  ; was: loc_523EC
                addq.w  #2,4(a5)
                move.b  #1,$47C(a5)
                clr.l   $41C(a5)
                move.w  #$80,$11C(a5)
; Accelerate the boss and stage scroll for $80 frames
Boss_ZLeoRunScrollAcceleration:                         ; DATA XREF: ROM:00051BAE   o  ; was: loc_52400
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginScrollCruise
                addi.l  #$4000,$41C(a5)
                cmpi.l  #$78000,$41C(a5)
                bmi.s   Boss_ZLeoApplyScrollAcceleration
                move.l  #$78000,$41C(a5)
Boss_ZLeoApplyScrollAcceleration:                       ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+AE   j  ; was: loc_52420
                move.l  $41C(a5),d0
                asl.l   #2,d0
                add.l   d0,$35C(a5)
                cmpi.w  #$180,$35C(a5)
                bmi.s   Boss_ZLeoRenderScrollAcceleration
                move.w  #$180,$35C(a5)
Boss_ZLeoRenderScrollAcceleration:                      ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+C8   j  ; was: loc_52438
                bsr.w   Boss_ZLeoAdvanceVerticalScrollAndQueueRow
                lea     Boss_ZLeoScrollingLaserBurstPoses(pc),a1
                nop
                bra.w   Boss_ZLeoRenderCompositeFrame
; ---------------------------------------------------------------------------
Boss_ZLeoBeginScrollCruise:                             ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+9C   j  ; was: loc_52446
                addq.w  #2,4(a5)
                move.w  #$80,$11C(a5)
; Hold the established scroll motion for another $80 frames
Boss_ZLeoRunScrollCruise:                               ; DATA XREF: ROM:00051BB0   o  ; was: loc_52450
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginScrollReversal
Boss_ZLeoUpdateScrollingAttackFrame:                    ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose:Boss_ZLeoRenderScrollingDropAttack   j  ; was: loc_52456
                bsr.w   Boss_ZLeoAdvanceVerticalScrollAndQueueRow
                bsr.w   Boss_ZLeoStreamTileChunkForCameraY
                bra.w   Boss_ZLeoBuildHBlankRegisterBuffer
; ---------------------------------------------------------------------------
Boss_ZLeoBeginScrollReversal:                           ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+EC   j  ; was: loc_52462
                addq.w  #2,4(a5)
                move.l  #$FFC00000,(Entity57YPos).w
                move.l  #$50000,(Entity57YVel).w
                move.w  #$120,(PlayerXPosition).w
                move.w  (Entity57YPos).w,d0
                subi.w  #$20,d0                         ; ' '
                move.w  d0,(PlayerYPosition).w
                move.w  #$80,$11C(a5)
; Reverse the boss and stage motion, then wait before the hold state
Boss_ZLeoRunScrollReversal:                             ; DATA XREF: ROM:00051BB2   o  ; was: loc_5248E
                tst.w   (PlayerScriptStateOffset).w
                beq.s   Boss_ZLeoUpdateStageScrollReversal
                cmpi.w  #$C0,(Entity57YPos).w
                bmi.s   Boss_ZLeoUpdateStageScrollReversal
                clr.w   (PlayerScriptStateOffset).w
                bclr    #2,(PlayerRestrictionFlags).w
                bclr    #0,(StageTimerPauseFlag).w
Boss_ZLeoUpdateStageScrollReversal:                     ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+12A   j  ; was: loc_524AC
                                        ; Boss_ZLeoRunScrollingLaserEntryPose+132   j
                btst    #2,(Entity57Flags).w
                beq.s   Boss_ZLeoCountPostReversalDelay
                subi.l  #$880,(Entity57YVel).w
                bpl.s   Boss_ZLeoAccelerateReverseBossMotion
                bclr    #2,(Entity57Flags).w
                clr.l   (Entity57YVel).w
Boss_ZLeoCountPostReversalDelay:                        ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+14A   j  ; was: loc_524C8
                subq.w  #1,$11C(a5)
                bmi.s   Boss_ZLeoBeginDropAttackHold
Boss_ZLeoAccelerateReverseBossMotion:                   ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+154   j  ; was: loc_524CE
                subi.l  #$2000,$41C(a5)
                cmpi.l  #$FFF88000,$41C(a5)
                bpl.s   Boss_ZLeoFinishReverseBossMotionUpdate
                move.l  #$FFF88000,$41C(a5)
Boss_ZLeoFinishReverseBossMotionUpdate:                 ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+176   j  ; was: loc_524E8
                bra.s   Boss_ZLeoUpdateScrollingDropAttack
; ---------------------------------------------------------------------------
Boss_ZLeoBeginDropAttackHold:                           ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+164   j  ; was: loc_524EA
                addq.w  #2,4(a5)
; Continue the drop-projectile attack until the scroll threshold is reached
Boss_ZLeoRunDropAttackHold:                             ; DATA XREF: ROM:00051BB4   o  ; was: loc_524EE
                cmpi.w  #$240,(SecondaryCameraYPos).w
                bmi.s   Boss_ZLeoBeginRisingReturn
Boss_ZLeoUpdateScrollingDropAttack:                     ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose:Boss_ZLeoFinishReverseBossMotionUpdate   j  ; was: loc_524F6
                bsr.w   Boss_ZLeoRotateAttackPalette
                tst.w   (PlayerScriptStateOffset).w
                bne.s   Boss_ZLeoRenderScrollingDropAttack
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_ZLeoRenderScrollingDropAttack
                bsr.w   Boss_ZLeoSpawnDropAttackPair
Boss_ZLeoRenderScrollingDropAttack:                     ; CODE XREF: Boss_ZLeoRunScrollingLaserEntryPose+196   j  ; was: loc_5250E
                                        ; Boss_ZLeoRunScrollingLaserEntryPose+1A0   j
                bra.w   Boss_ZLeoUpdateScrollingAttackFrame
; End of function Boss_ZLeoRunScrollingLaserEntryPose
; Cycles Z-Leo palette colors based on frame counter - rotates 3 palette entries in 4 different patterns
