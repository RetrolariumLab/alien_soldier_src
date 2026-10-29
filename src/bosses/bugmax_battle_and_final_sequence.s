; Transfer the tile block used when the linked assembly reaches battle rotation
Gfx_BugmaxTransferBattleTileBlock:                      ; CODE XREF: Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle+26   p  ; was: sub_4C938
                lea     Gfx_BugmaxBattleTileTransferDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Gfx_BugmaxTransferBattleTileBlock
; ---------------------------------------------------------------------------
Gfx_BugmaxBattleTileTransferDescriptor: dc.w    $6330, $2000, $104, 0, 0, 0, 0, 0  ; was: word_4C944
                                        ; DATA XREF: Gfx_BugmaxTransferBattleTileBlock   o

; Initialize the controller, primary and secondary linked chains, and history buffers
Boss_BugmaxInitializeBattleObjectChains:                ; DATA XREF: ROM:0004C3F0   o  ; was: sub_4C954
                addq.w  #2,4(a5)
                move.l  (SeventhEntityXVel).w,d0
                move.l  d0,$18(a5)
                move.l  (SeventhEntityYVel).w,d0
                asr.l   #1,d0
                move.l  d0,$1C(a5)
                move.w  #$100,(SharedScratchLong5+2).w
                move.b  #$40,$20(a5)                    ; '@'
                move.l  #Boss_BugmaxBattleControllerFrame,8(a5)
                move.w  #$300,$E(a5)
                move.w  #$CD80,2(a5)
                move.w  #$80,$26(a5)
                move.l  #$F808F808,$2C(a5)
                move.l  #$F808F808,$28(a5)
                move.w  #$14,$24(a5)
                move.w  #0,$4C(a5)
                move.w  #0,$4E(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.l  #Boss_BugmaxCentralPartToggleFrame00,8(a0)
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.w  #$80,$26(a0)
                move.l  #$F808F808,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.b  #$80,$23(a0)
                move.w  #$1C,$24(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  #$180,$4C(a0)
                move.w  #0,$4E(a0)
                move.w  #$40,$50(a0)                    ; '@'
                moveq   #0,d6
                move.w  #4,d7
                movea.w #(TertiaryEntityType-M68K_RAM),a0
Boss_BugmaxInitializePrimaryLinkedChainLoop:            ; CODE XREF: Boss_BugmaxInitializeBattleObjectChains+110   j  ; was: loc_4CA12
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.w  #$80,$26(a0)
                move.l  #$F808F808,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #2,$24(a0)
                move.b  $20(a5),$20(a0)
                move.w  #$80,$4C(a0)
                lea     Boss_BugmaxPrimaryLinkedPartDescriptors(pc),a1
                nop
                move.w  (a1,d6.w),$50(a0)
                move.w  2(a1,d6.w),$4E(a0)
                move.l  4(a1,d6.w),8(a0)
                addq.w  #8,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxInitializePrimaryLinkedChainLoop
                moveq   #0,d6
                lea     Boss_BugmaxSecondaryLinkedPartMappings(pc),a1
                nop
                move.w  #7,d7
                movea.w #(EighthEntityType-M68K_RAM),a0
Boss_BugmaxInitializeSecondaryLinkedChainLoop:          ; CODE XREF: Boss_BugmaxInitializeBattleObjectChains+146   j  ; was: loc_4CA78
                move.w  #$10,(a0)
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.b  $20(a5),$20(a0)
                move.l  (a1,d6.w),8(a0)
                addq.w  #4,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxInitializeSecondaryLinkedChainLoop
                move.l  #$FF01FF01,-$34(a0)
                move.w  #$10,-$3A(a0)
                move.b  #$40,-$3F(a0)                   ; '@'
                move.w  #$20,(SharedScratchLong4).w     ; ' '
                addq.w  #2,$5E(a5)
                move.w  $5C(a5),$4A(a5)
                move.w  #$180,(SecondaryEntityWork4C).w
                move.w  #$80,(TertiaryEntityWork4C).w
                move.w  #$A0,d0
                lea     (BugmaxAngleHistoryRows).w,a0
                move.w  #7,d7
Boss_BugmaxSeedSecondaryAngleHistoryRowsLoop:           ; CODE XREF: Boss_BugmaxInitializeBattleObjectChains+190   j  ; was: loc_4CADA
                move.w  #3,d6
Boss_BugmaxSeedSecondaryAngleHistoryRowLoop:            ; CODE XREF: Boss_BugmaxInitializeBattleObjectChains+18C   j  ; was: loc_4CADE
                move.w  d0,(a0)+
                dbf     d6,Boss_BugmaxSeedSecondaryAngleHistoryRowLoop
                dbf     d7,Boss_BugmaxSeedSecondaryAngleHistoryRowsLoop
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                swap    d0
                move.w  $14(a5),d0
                lea     (BugmaxPositionHistory).w,a0
                move.w  #7,d7
Boss_BugmaxSeedPrimaryPositionHistoryLoop:              ; CODE XREF: Boss_BugmaxInitializeBattleObjectChains+1AC   j  ; was: loc_4CAFE
                move.l  d0,(a0)+
                dbf     d7,Boss_BugmaxSeedPrimaryPositionHistoryLoop
                rts
; End of function Boss_BugmaxInitializeBattleObjectChains
; ---------------------------------------------------------------------------
Boss_BugmaxPrimaryLinkedPartDescriptors:    dc.w    $5C  ; field_0  ; was: stru_4CB06
                                        ; DATA XREF: Boss_BugmaxInitializeBattleObjectChains+F2   o
                dc.w    0                               ; field_2
                dc.l    Boss_BugmaxPrimaryLinkFrame00   ; field_4
                dc.w    $40                             ; field_0
                dc.w    $FFDC                           ; field_2
                dc.l    Boss_BugmaxPrimaryLinkFrame01   ; field_4
                dc.w    $30                             ; field_0
                dc.w    $FFD4                           ; field_2
                dc.l    Boss_BugmaxPrimaryLinkFrame01   ; field_4
                dc.w    $2C                             ; field_0
                dc.w    $FFC8                           ; field_2
                dc.l    Boss_BugmaxPrimaryLinkFrame02   ; field_4
                dc.w    $28                             ; field_0
                dc.w    $FFB8                           ; field_2
                dc.l    Boss_BugmaxPrimaryLinkFrame02   ; field_4
Boss_BugmaxSecondaryLinkedPartMappings: dc.l    Boss_BugmaxSecondaryLinkFrame00  ; DATA XREF: Boss_BugmaxInitializeBattleObjectChains+116   o  ; was: off_4CB2E
                dc.l    Boss_BugmaxSecondaryLinkFrame00
                dc.l    Boss_BugmaxSecondaryLinkFrame00
                dc.l    Boss_BugmaxSecondaryLinkFrame01
                dc.l    Boss_BugmaxSecondaryLinkFrame01
                dc.l    Boss_BugmaxSecondaryLinkFrame01
                dc.l    Boss_BugmaxSecondaryLinkFrame01
                dc.l    Boss_BugmaxSecondaryLinkFrame01

; Advance the linked assembly rotation until shared angle $140
Boss_BugmaxRotateLinkedAssemblyToward140:               ; DATA XREF: ROM:0004C3F2   o  ; was: sub_4CB4E
                addi.l  #$1800,$1C(a5)
                addi.w  #$10,(SharedScratchLong5+2).w
                andi.w  #$1F0,(SharedScratchLong5+2).w
                cmpi.w  #$140,(SharedScratchLong5+2).w
                bne.w   Boss_BugmaxRotateToward140Return
                addq.w  #2,4(a5)
Boss_BugmaxRotateToward140Return:                       ; CODE XREF: Boss_BugmaxRotateLinkedAssemblyToward140+1A   j  ; was: locret_4CB70
                rts
; End of function Boss_BugmaxRotateLinkedAssemblyToward140
; Continue linked-assembly rotation to $180, then enable battle collision and bounds
Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle:  ; DATA XREF: ROM:0004C3F4   o  ; was: sub_4CB72
                addi.l  #$1800,$1C(a5)
                bsr.w   Boss_BugmaxUpdateBodyAnchorFromScrollPhase
                subi.w  #8,(SharedScratchLong5+2).w
                andi.w  #$1F8,(SharedScratchLong5+2).w
                cmpi.w  #$180,(SharedScratchLong5+2).w
                bne.w   Boss_BugmaxRotateToward180Return
                addq.w  #2,4(a5)
                bsr.w   Gfx_BugmaxTransferBattleTileBlock
                move.b  #$D0,$21(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.b  #$D0,$21(a0)
                move.w  #$60,$50(a0)                    ; '`'
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                move.w  #2,d7
Boss_BugmaxEnablePrimaryLinkedPartCollisionLoop:        ; CODE XREF: Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle+52   j  ; was: loc_4CBBA
                move.b  #$D0,$21(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxEnablePrimaryLinkedPartCollisionLoop
                move.w  #$10,$48(a5)
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #2,(PlaneBScrollModeFlags).w
                move.w  #$E,(RasterLayoutOffset).w
                move.w  #$140,(SharedScratchLong3).w
                move.w  #$140,(SharedScratchLong3+2).w
                move.l  #$C0000,(SharedScratchLong2).w
                addq.w  #2,$5E(a5)
Boss_BugmaxRotateToward180Return:                       ; CODE XREF: Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle+1E   j  ; was: locret_4CBFC
                rts
; End of function Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle
; Load the first battle tile set after its local delay
Gfx_BugmaxLoadTimedBattleTileSet:                       ; DATA XREF: ROM:0004C3F6   o  ; was: sub_4CBFE
                subq.w  #1,$48(a5)
                bne.w   Gfx_BugmaxTimedBattleTileLoadReturn
                addq.w  #2,4(a5)
                lea     Gfx_BugmaxTimedBattleTileSetDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Gfx_BugmaxTimedBattleTileSetDescriptor: dc.w    $6330, $2000, $302, $B3B2, $B1B0, $B7B6, $B5B4, $BBBA, $B900  ; was: word_4CC16
                                        ; DATA XREF: Gfx_BugmaxLoadTimedBattleTileSet+C   o
; ---------------------------------------------------------------------------
Gfx_BugmaxTimedBattleTileLoadReturn:                    ; CODE XREF: Gfx_BugmaxLoadTimedBattleTileSet+4   j  ; was: locret_4CC28
                rts
; End of function Gfx_BugmaxLoadTimedBattleTileSet
; Load the second battle tile set after the graphics queue is ready
Gfx_BugmaxLoadQueuedBattleTileSet:                      ; DATA XREF: ROM:0004C3F8   o  ; was: sub_4CC2A
                tst.b   (DataLoaderControl).w
                bmi.s   Gfx_BugmaxQueuedBattleTileLoadReturn
                addq.w  #2,4(a5)
                lea     Gfx_BugmaxQueuedBattleTileSetDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Gfx_BugmaxQueuedBattleTileSetDescriptor:    dc.w    $6930, $2000, $302, $DBDA, $D900, $D7D6, $D5D4, $D3D2, $D1D0  ; was: word_4CC40
                                        ; DATA XREF: Gfx_BugmaxLoadQueuedBattleTileSet+A   o
; ---------------------------------------------------------------------------
Gfx_BugmaxQueuedBattleTileLoadReturn:                   ; CODE XREF: Gfx_BugmaxLoadQueuedBattleTileSet+4   j  ; was: locret_4CC52
                rts
; End of function Gfx_BugmaxLoadQueuedBattleTileSet
; Settle the distributed chain bend from $20 to the battle baseline $18
Boss_BugmaxSettleChainBendAtBattleBaseline:             ; DATA XREF: ROM:0004C3FA   o  ; was: sub_4CC54
                bsr.w   Boss_BugmaxUpdateBattleMovement
                subq.w  #1,(SharedScratchLong4).w
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                cmpi.w  #$18,(SharedScratchLong4).w
                bne.s   Boss_BugmaxChainBendSettlementReturn
                clr.w   (SharedScratchLong9+2).w
                addq.w  #2,4(a5)
Boss_BugmaxChainBendSettlementReturn:                   ; CODE XREF: Boss_BugmaxSettleChainBendAtBattleBaseline+12   j  ; was: locret_4CC70
                rts
; End of function Boss_BugmaxSettleChainBendAtBattleBaseline
; Select the next battle pattern preset from player position and the fixed sequence
Boss_BugmaxSelectBattlePattern:                         ; DATA XREF: ROM:0004C3FC   o  ; was: sub_4CC72
                clr.b   (SharedScratchLong6+1).w
                clr.w   (SharedScratchLong9).w
                bsr.w   Boss_BugmaxUpdateBattleMovement
                move.w  (PlayerCenterX).w,d0
                add.w   (PrimaryCameraXPosition).w,d0
                cmpi.w  #$530,d0
                bcc.w   Boss_BugmaxChooseRetryOrChainStrikePattern
Boss_BugmaxApplyNextBattlePatternPreset:                ; CODE XREF: Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady+48   j  ; was: loc_4CC8E
                clr.w   $54(a5)
                move.w  $56(a5),d0
                move.w  Boss_BugmaxBattlePatternPresetSequence(pc,d0.w),(SharedScratchLong9+2).w
                bsr.s   Boss_BugmaxDispatchBattlePatternPreset
                addq.w  #2,$56(a5)
                andi.w  #$1E,$56(a5)
                rts
; End of function Boss_BugmaxSelectBattlePattern
; Dispatch one of the three battle movement presets
Boss_BugmaxDispatchBattlePatternPreset:                 ; CODE XREF: Boss_BugmaxSelectBattlePattern+2A   p  ; was: sub_4CCAA
                move.w  (SharedScratchLong9+2).w,d0
                lea     Boss_BugmaxBattlePatternPresetHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_BugmaxDispatchBattlePatternPreset
; ---------------------------------------------------------------------------
Boss_BugmaxBattlePatternPresetHandlers: dc.w    Boss_BugmaxApplyUpperMovementBandPreset-*  ; DATA XREF: Boss_BugmaxDispatchBattlePatternPreset+4   o  ; was: off_4CCB6
                dc.w    Boss_BugmaxEnterSineVolleyMovementPreset-*
                dc.w    Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady-*
Boss_BugmaxBattlePatternPresetSequence: dc.w    4, 0, 4, 2, 4, 0, 4, 2, 4, 2, 4, 0, 4, 2, 4, 0  ; was: word_4CCBC
                                        ; DATA XREF: Boss_BugmaxSelectBattlePattern+24   r

; Configure the movement band and enter the sine-projectile volley
Boss_BugmaxEnterSineVolleyMovementPreset:               ; CODE XREF: Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady+16   j  ; was: sub_4CCDC
                                        ; Boss_BugmaxApplyUpperMovementBandPreset+12   j
                                        ; DATA XREF:
                move.w  #$80,(SharedScratchLong3).w
                move.w  #$80,(SharedScratchLong3+2).w
                move.w  #$B0,(SharedScratchLong8).w
                move.w  #$20,(SharedScratchLong8+2).w   ; ' '
                move.w  #$44,4(a5)                      ; 'D'
                rts
; End of function Boss_BugmaxEnterSineVolleyMovementPreset
; Enter the spread volley only while its shared inhibit flag is clear
Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady:    ; DATA XREF: ROM:0004CCBA   o  ; was: sub_4CCFC
                tst.b   (SharedScratchLong6+3).w
                beq.s   Boss_BugmaxConfigureSpreadVolleyMovementPreset
                bne.w   Boss_BugmaxBattlePatternPresetReturn
                move.w  (PlayerCenterY).w,d0
                add.w   (PrimaryCameraXPosition).w,d0
                cmpi.w  #$530,d0
                bcs.w   Boss_BugmaxEnterSineVolleyMovementPreset
                bra.w   Boss_BugmaxChooseRetryOrChainStrikePattern
; ---------------------------------------------------------------------------
Boss_BugmaxConfigureSpreadVolleyMovementPreset:         ; CODE XREF: Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady+4   j  ; was: loc_4CD1A
                move.w  #$80,(SharedScratchLong3).w
                move.w  #$140,(SharedScratchLong3+2).w
                move.w  #$C0,(SharedScratchLong8).w
                move.w  #$20,(SharedScratchLong8+2).w   ; ' '
                move.w  #$26,4(a5)                      ; '&'
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxChooseRetryOrChainStrikePattern:             ; CODE XREF: Boss_BugmaxSelectBattlePattern+18   j  ; was: loc_4CD3A
                                        ; Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady+1A   j
                addq.w  #1,$54(a5)
                andi.w  #3,$54(a5)
                beq.w   Boss_BugmaxApplyNextBattlePatternPreset
                move.w  #$140,(SharedScratchLong3).w
                move.w  #$100,(SharedScratchLong3+2).w
                move.w  #$E0,(SharedScratchLong8).w
                move.w  #$20,(SharedScratchLong8+2).w   ; ' '
                move.w  #$32,4(a5)                      ; '2'
                rts
; End of function Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady
; Apply the upper movement band, or redirect an inhibited selection
Boss_BugmaxApplyUpperMovementBandPreset:                ; DATA XREF: ROM:Boss_BugmaxBattlePatternPresetHandlers   o  ; was: sub_4CD68
                tst.b   (SharedScratchLong6+3).w
                beq.s   Boss_BugmaxConfigureUpperMovementBandPreset
                move.w  (PlayerCenterY).w,d0
                add.w   (PrimaryCameraXPosition).w,d0
                cmpi.w  #$530,d0
                bcs.w   Boss_BugmaxEnterSineVolleyMovementPreset
                bra.w   Boss_BugmaxChooseRetryOrChainStrikePattern
; ---------------------------------------------------------------------------
Boss_BugmaxConfigureUpperMovementBandPreset:            ; CODE XREF: Boss_BugmaxApplyUpperMovementBandPreset+4   j  ; was: loc_4CD82
                move.w  #$140,(SharedScratchLong3).w
                move.w  #$140,(SharedScratchLong3+2).w
                move.w  #$C0,(SharedScratchLong8).w
                move.w  #$80,(SharedScratchLong8+2).w
Boss_BugmaxBattlePatternPresetReturn:                   ; CODE XREF: Boss_BugmaxEnterSpreadVolleyMovementPresetWhenReady+6   j  ; was: locret_4CD9A
                rts
; End of function Boss_BugmaxApplyUpperMovementBandPreset
; Begin the spread-projectile volley stance
Boss_BugmaxBeginSpreadVolleyStance:                     ; DATA XREF: ROM:0004C3FE   o  ; was: sub_4CD9C
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bset    #1,(SharedScratchLong6+1).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxBeginSpreadVolleyStance
; Increase the wave step from $0C to $18 and arm the spread volley
Boss_BugmaxIncreaseWaveStepForSpreadVolley:             ; DATA XREF: ROM:0004C400   o  ; was: sub_4CDAC
                bsr.w   Boss_BugmaxUpdateBattleMovement
                addq.w  #1,(SharedScratchLong2).w
                cmpi.w  #$18,(SharedScratchLong2).w
                bne.s   Boss_BugmaxSpreadVolleyWaveStepReturn
                clr.b   (SharedScratchLong6+1).w
                clr.w   (SharedScratchLong9).w
                bset    #0,(SharedScratchLong6+1).w
                bclr    #0,(SharedScratchLong7).w
                move.w  #$10,$4A(a5)
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_BugmaxSpreadVolleyWaveStepReturn:                  ; CODE XREF: Boss_BugmaxIncreaseWaveStepForSpreadVolley+E   j  ; was: locret_4CDE0
                rts
; End of function Boss_BugmaxIncreaseWaveStepForSpreadVolley
; Approach the spread-volley target until timeout or the target-reached flag
Boss_BugmaxApproachSpreadVolleyTarget:                  ; DATA XREF: ROM:0004C402   o  ; was: sub_4CDE2
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                subq.w  #1,$48(a5)
                beq.s   Boss_BugmaxFinishSpreadVolleyApproach
                bclr    #0,(SharedScratchLong7).w
                beq.s   Boss_BugmaxSpreadVolleyApproachReturn
Boss_BugmaxFinishSpreadVolleyApproach:                  ; CODE XREF: Boss_BugmaxApproachSpreadVolleyTarget+C   j  ; was: loc_4CDF8
                addq.w  #2,4(a5)
Boss_BugmaxSpreadVolleyApproachReturn:                  ; CODE XREF: Boss_BugmaxApproachSpreadVolleyTarget+14   j  ; was: locret_4CDFC
                rts
; End of function Boss_BugmaxApproachSpreadVolleyTarget
; Allocate and initialize one horizontally scattered projectile
Boss_BugmaxSpawnSpreadProjectile:                       ; DATA XREF: ROM:0004C404   o  ; was: sub_4CDFE
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_BugmaxSpreadProjectileSpawnReturn
                bsr.w   Projectile_InitBugmaxSpread
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_BugmaxSpreadProjectileSpawnReturn:                 ; CODE XREF: Boss_BugmaxSpawnSpreadProjectile+E   j  ; was: locret_4CE1C
                rts
; End of function Boss_BugmaxSpawnSpreadProjectile
; Repeat the scattered projectile spawn for the configured volley count
Boss_BugmaxRepeatSpreadProjectileVolley:                ; DATA XREF: ROM:0004C406   o  ; was: sub_4CE1E
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                tst.b   (SharedScratchLong6+3).w
                bne.s   Boss_BugmaxFinishSpreadProjectileVolley
                jsr     (Physics_GetPlayerDelta).l
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxSpreadVolleyRepeatReturn
                subq.w  #1,$4A(a5)
                beq.s   Boss_BugmaxFinishSpreadProjectileVolley
                subq.w  #2,4(a5)
Boss_BugmaxSpreadVolleyRepeatReturn:                    ; CODE XREF: Boss_BugmaxRepeatSpreadProjectileVolley+18   j  ; was: locret_4CE42
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxFinishSpreadProjectileVolley:                ; CODE XREF: Boss_BugmaxRepeatSpreadProjectileVolley+C   j  ; was: loc_4CE44
                                        ; Boss_BugmaxRepeatSpreadProjectileVolley+1E   j
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxRepeatSpreadProjectileVolley
; Reduce the wave step back to $0C after the spread volley
Boss_BugmaxReduceWaveStepAfterSpreadVolley:             ; DATA XREF: ROM:0004C408   o  ; was: sub_4CE4A
                bsr.w   Boss_BugmaxUpdateBattleMovement
                subq.w  #1,(SharedScratchLong2).w
                cmpi.w  #$C,(SharedScratchLong2).w
                bne.s   Boss_BugmaxSpreadVolleyWaveReductionReturn
                move.w  #$24,4(a5)                      ; '$'
Boss_BugmaxSpreadVolleyWaveReductionReturn:             ; CODE XREF: Boss_BugmaxReduceWaveStepAfterSpreadVolley+E   j  ; was: locret_4CE60
                rts
; End of function Boss_BugmaxReduceWaveStepAfterSpreadVolley
; Set the horizontal approach target used by the aimed linked-chain strike
Boss_BugmaxSetChainStrikeApproachTarget:                ; DATA XREF: ROM:0004C40A   o  ; was: sub_4CE62
                bsr.w   Boss_BugmaxUpdateBattleMovement
                clr.b   (SharedScratchLong6+1).w
                bclr    #0,(SharedScratchLong7).w
                bset    #0,(SharedScratchLong6+1).w
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   (PlayerCenterX).w,d0
                subi.w  #$80,d0
                move.w  d0,(SharedScratchLong9).w
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxSetChainStrikeApproachTarget
; Approach the linked-chain strike target until timeout or target reached
Boss_BugmaxApproachChainStrikeTarget:                   ; DATA XREF: ROM:0004C40C   o  ; was: sub_4CE92
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                bclr    #0,(SharedScratchLong7).w
                bne.s   Boss_BugmaxFinishChainStrikeApproach
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxChainStrikeApproachReturn
Boss_BugmaxFinishChainStrikeApproach:                   ; CODE XREF: Boss_BugmaxApproachChainStrikeTarget+E   j  ; was: loc_4CEA8
                clr.b   (SharedScratchLong6+1).w
                bset    #1,(SharedScratchLong6+1).w
                addq.w  #2,4(a5)
Boss_BugmaxChainStrikeApproachReturn:                   ; CODE XREF: Boss_BugmaxApproachChainStrikeTarget+14   j  ; was: locret_4CEB6
                rts
; End of function Boss_BugmaxApproachChainStrikeTarget
; Select shared-angle geometry and begin the aimed linked-chain strike
Boss_BugmaxBeginAimedChainStrike:                       ; DATA XREF: ROM:0004C40E   o  ; was: sub_4CEB8
                bsr.w   Boss_BugmaxUpdateBattleMovement
                move.w  #$60,$48(a5)                    ; '`'
                move.b  #1,(SharedScratchLong6+2).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxBeginAimedChainStrike
; Animate the chain bend, aim its shared angle at the player, and enable collision
Boss_BugmaxAnimateAndAimChainStrike:                    ; DATA XREF: ROM:0004C410   o  ; was: sub_4CECE
                bsr.w   Boss_BugmaxUpdateBattleMovement
                move.w  $48(a5),d0
                move.w  Boss_BugmaxChainStrikeBendSequence(pc,d0.w),(SharedScratchLong4).w
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                subq.w  #2,$48(a5)
                bpl.s   Boss_BugmaxChainStrikeAimReturn
                jsr     (Math_CalculateAngleToPlayer).l
                cmpi.w  #$100,d2
                bcc.s   Boss_BugmaxClampStrikeAngleToUpperBoundary
                cmpi.w  #$40,d2                         ; '@'
                bcs.s   Boss_BugmaxStoreAimedChainStrikeAngle
                move.w  #$40,d2                         ; '@'
                bra.s   Boss_BugmaxStoreAimedChainStrikeAngle
; ---------------------------------------------------------------------------
Boss_BugmaxClampStrikeAngleToUpperBoundary:             ; CODE XREF: Boss_BugmaxAnimateAndAimChainStrike+22   j  ; was: loc_4CEFE
                cmpi.w  #$1C0,d2
                bhi.s   Boss_BugmaxStoreAimedChainStrikeAngle
                move.w  #$1C0,d2
Boss_BugmaxStoreAimedChainStrikeAngle:                  ; CODE XREF: Boss_BugmaxAnimateAndAimChainStrike+28   j  ; was: loc_4CF08
                                        ; Boss_BugmaxAnimateAndAimChainStrike+2E   j
                move.w  d2,(SharedScratchLong5).w
                bsr.w   Boss_BugmaxConfigureAimedChainHitbox
                addq.w  #2,4(a5)
                move.b  #$E2,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_BugmaxChainStrikeAimReturn:                        ; CODE XREF: Boss_BugmaxAnimateAndAimChainStrike+16   j  ; was: locret_4CF1E
                rts
; End of function Boss_BugmaxAnimateAndAimChainStrike
; ---------------------------------------------------------------------------
Boss_BugmaxChainStrikeBendSequence: dc.w    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F  ; was: word_4CF20
                                        ; DATA XREF: Boss_BugmaxAnimateAndAimChainStrike+8   r
                dc.w    $20, $1F, $1E, $1D, $1C, $1B, $1A, $19
                dc.w    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
                dc.w    $20, $1F, $1E, $1D, $1C, $1B, $1A, $19
                dc.w    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
                dc.w    $20, $1F, $1E, $1D, $1C, $1B, $1A, $19

; Extend the aimed linked-chain strike while processing contact effects
Boss_BugmaxExtendAimedChainStrike:                      ; DATA XREF: ROM:0004C412   o  ; was: sub_4CF80
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxHandleAimedChainContactEffect
                subq.w  #1,(SharedScratchLong4).w
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                tst.w   (SharedScratchLong4).w
                bne.s   Boss_BugmaxChainStrikeExtensionReturn
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Boss_BugmaxChainStrikeExtensionReturn:                  ; CODE XREF: Boss_BugmaxExtendAimedChainStrike+14   j  ; was: locret_4CFA0
                rts
; End of function Boss_BugmaxExtendAimedChainStrike
; Hold the fully extended linked-chain strike for eight frames
Boss_BugmaxHoldExtendedChainStrike:                     ; DATA XREF: ROM:0004C414   o  ; was: sub_4CFA2
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxHandleAimedChainContactEffect
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxExtendedChainStrikeHoldReturn
                addq.w  #2,4(a5)
Boss_BugmaxExtendedChainStrikeHoldReturn:               ; CODE XREF: Boss_BugmaxHoldExtendedChainStrike+C   j  ; was: locret_4CFB4
                rts
; End of function Boss_BugmaxHoldExtendedChainStrike
; Retract the aimed linked-chain strike and disable its hitbox near the midpoint
Boss_BugmaxRetractAimedChainStrike:                     ; DATA XREF: ROM:0004C416   o  ; was: sub_4CFB6
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxHandleContactOrDisableChainHitbox
                subq.w  #1,(SharedScratchLong4).w
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                cmpi.w  #$FFE0,(SharedScratchLong4).w
                bne.s   Boss_BugmaxChainStrikeRetractionReturn
                addq.w  #2,4(a5)
Boss_BugmaxChainStrikeRetractionReturn:                 ; CODE XREF: Boss_BugmaxRetractAimedChainStrike+16   j  ; was: locret_4CFD2
                rts
; End of function Boss_BugmaxRetractAimedChainStrike
; Reset the chain bend before its settling phase
Boss_BugmaxResetChainStrikeBend:                        ; DATA XREF: ROM:0004C418   o  ; was: sub_4CFD4
                bsr.w   Boss_BugmaxUpdateBattleMovement
                move.w  #$20,(SharedScratchLong4).w     ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxResetChainStrikeBend
; Settle the chain bend at $18 and return to battle selection
Boss_BugmaxSettleChainAfterStrike:                      ; DATA XREF: ROM:0004C41A   o  ; was: sub_4CFE4
                bsr.w   Boss_BugmaxUpdateBattleMovement
                subq.w  #1,(SharedScratchLong4).w
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                cmpi.w  #$18,(SharedScratchLong4).w
                bne.s   Boss_BugmaxChainStrikeSettlementReturn
                clr.b   (SharedScratchLong6+2).w
                clr.w   (SharedScratchLong5).w
                move.w  #$24,4(a5)                      ; '$'
Boss_BugmaxChainStrikeSettlementReturn:                 ; CODE XREF: Boss_BugmaxSettleChainAfterStrike+12   j  ; was: locret_4D006
                rts
; End of function Boss_BugmaxSettleChainAfterStrike
; Adjust and clamp the shared chain bend from directional input
Boss_BugmaxAdjustChainBendFromInput:                    ; was: sub_4D008
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_BugmaxCheckChainBendIncreaseInput
                addi.w  #-2,(SharedScratchLong4).w
Boss_BugmaxCheckChainBendIncreaseInput:                 ; CODE XREF: Boss_BugmaxAdjustChainBendFromInput+6   j  ; was: loc_4D016
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_BugmaxClampInputChainBendRange
                addi.w  #2,(SharedScratchLong4).w
Boss_BugmaxClampInputChainBendRange:                    ; CODE XREF: Boss_BugmaxAdjustChainBendFromInput+14   j  ; was: loc_4D024
                cmpi.w  #$40,(SharedScratchLong4).w     ; '@'
                blt.w   Boss_BugmaxClampInputChainBendMinimum
                move.w  #$40,(SharedScratchLong4).w     ; '@'
                bra.s   Boss_BugmaxApplyInputChainBend
; ---------------------------------------------------------------------------
Boss_BugmaxClampInputChainBendMinimum:                  ; CODE XREF: Boss_BugmaxAdjustChainBendFromInput+22   j  ; was: loc_4D036
                cmpi.w  #$FFC0,(SharedScratchLong4).w
                bge.w   Boss_BugmaxApplyInputChainBend
                move.w  #$FFC0,(SharedScratchLong4).w
Boss_BugmaxApplyInputChainBend:                         ; CODE XREF: Boss_BugmaxAdjustChainBendFromInput+2C   j  ; was: loc_4D046
                                        ; Boss_BugmaxAdjustChainBendFromInput+34   j
                bsr.w   Boss_BugmaxDistributeSecondaryChainAngleOffsets
                rts
; End of function Boss_BugmaxAdjustChainBendFromInput
; Distribute the shared bend as increasing angle offsets across eight linked records
Boss_BugmaxDistributeSecondaryChainAngleOffsets:        ; CODE XREF: Boss_BugmaxSettleChainBendAtBattleBaseline+8   p  ; was: sub_4D04C
                                        ; Boss_BugmaxAnimateAndAimChainStrike+E   p
                move.w  (SharedScratchLong4).w,d0
                add.w   d0,d0
                bpl.s   Boss_BugmaxInitializeAngleOffsetDistribution
                neg.w   d0
Boss_BugmaxInitializeAngleOffsetDistribution:           ; CODE XREF: Boss_BugmaxDistributeSecondaryChainAngleOffsets+6   j  ; was: loc_4D056
                move.w  #$40,(SharedScratchLong4+2).w   ; '@'
                sub.w   d0,(SharedScratchLong4+2).w
                move.w  (SharedScratchLong4).w,d0
                moveq   #0,d6
                movea.w #(EighthEntityType-M68K_RAM),a0
                move.w  #2,d7
Boss_BugmaxDistributeFirstAngleOffsetGroupLoop:         ; CODE XREF: Boss_BugmaxDistributeSecondaryChainAngleOffsets+2E   j  ; was: loc_4D06E
                move.w  d6,$4E(a0)
                add.w   d0,d6
                add.w   d0,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxDistributeFirstAngleOffsetGroupLoop
                move.w  #2,d7
Boss_BugmaxDistributeSecondAngleOffsetGroupLoop:        ; CODE XREF: Boss_BugmaxDistributeSecondaryChainAngleOffsets+44   j  ; was: loc_4D082
                move.w  d6,$4E(a0)
                add.w   d0,d6
                add.w   d0,d6
                add.w   d0,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxDistributeSecondAngleOffsetGroupLoop
                move.w  #1,d7
Boss_BugmaxDistributeFinalAngleOffsetGroupLoop:         ; CODE XREF: Boss_BugmaxDistributeSecondaryChainAngleOffsets+5C   j  ; was: loc_4D098
                move.w  d6,$4E(a0)
                add.w   d0,d6
                add.w   d0,d6
                add.w   d0,d6
                add.w   d0,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxDistributeFinalAngleOffsetGroupLoop
                rts
; End of function Boss_BugmaxDistributeSecondaryChainAngleOffsets
; Begin the sine-projectile volley stance
Boss_BugmaxBeginSineProjectileVolleyStance:             ; DATA XREF: ROM:0004C41C   o  ; was: sub_4D0AE
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bset    #1,(SharedScratchLong6+1).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxBeginSineProjectileVolleyStance
; Increase the wave step from $0C to $20 for the sine volley
Boss_BugmaxIncreaseWaveStepForSineVolley:               ; DATA XREF: ROM:0004C41E   o  ; was: sub_4D0BE
                bsr.w   Boss_BugmaxUpdateBattleMovement
                addq.w  #1,(SharedScratchLong2).w
                cmpi.w  #$20,(SharedScratchLong2).w     ; ' '
                bne.s   Boss_BugmaxSineVolleyWaveStepReturn
                addq.w  #2,4(a5)
Boss_BugmaxSineVolleyWaveStepReturn:                    ; CODE XREF: Boss_BugmaxIncreaseWaveStepForSineVolley+E   j  ; was: locret_4D0D2
                rts
; End of function Boss_BugmaxIncreaseWaveStepForSineVolley
; Choose the player position or one of two side-offset targets for the sine volley
Boss_BugmaxChooseSineVolleySideTarget:                  ; DATA XREF: ROM:0004C420   o  ; was: sub_4D0D4
                bsr.w   Boss_BugmaxUpdateBattleMovement
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                clr.b   (SharedScratchLong6+1).w
                bclr    #0,(SharedScratchLong7).w
                bset    #0,(SharedScratchLong6+1).w
                tst.b   (SharedScratchLong6+3).w
                bne.w   Boss_BugmaxUsePlayerPositionForSineVolley
                cmpi.b  #2,(SharedScratchLong9+2).w
                bne.w   Boss_BugmaxUsePlayerPositionForSineVolley
                cmpi.w  #$3C0,(PrimaryCameraXPosition).w
                beq.s   Boss_BugmaxSetSineVolleyRightSideTarget
                cmpi.w  #$460,(PrimaryCameraXPosition).w
                beq.s   Boss_BugmaxSetSineVolleyLeftSideTarget
                btst    #2,(ControllerHeldState).w
                bne.s   Boss_BugmaxSetSineVolleyRightSideTarget
                btst    #3,(ControllerHeldState).w
                bne.s   Boss_BugmaxSetSineVolleyLeftSideTarget
Boss_BugmaxUsePlayerPositionForSineVolley:              ; CODE XREF: Boss_BugmaxChooseSineVolleySideTarget+22   j  ; was: loc_4D124
                                        ; Boss_BugmaxChooseSineVolleySideTarget+2C   j
                clr.w   (SharedScratchLong9).w
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxSetSineVolleyRightSideTarget:                ; CODE XREF: Boss_BugmaxChooseSineVolleySideTarget+36   j  ; was: loc_4D12A
                                        ; Boss_BugmaxChooseSineVolleySideTarget+46   j
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   (PlayerCenterX).w,d0
                addi.w  #$D0,d0
                move.w  d0,(SharedScratchLong9).w
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxSetSineVolleyLeftSideTarget:                 ; CODE XREF: Boss_BugmaxChooseSineVolleySideTarget+3E   j  ; was: loc_4D13C
                                        ; Boss_BugmaxChooseSineVolleySideTarget+4E   j
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   (PlayerCenterX).w,d0
                addi.w  #-$D0,d0
                move.w  d0,(SharedScratchLong9).w
                rts
; End of function Boss_BugmaxChooseSineVolleySideTarget
; Approach the sine-volley target until close, reached, or timed out
Boss_BugmaxApproachSineVolleyTarget:                    ; DATA XREF: ROM:0004C422   o  ; was: sub_4D14E
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$20,d0                         ; ' '
                bcs.s   Boss_BugmaxFinishSineVolleyApproach
                bclr    #0,(SharedScratchLong7).w
                bne.s   Boss_BugmaxFinishSineVolleyApproach
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxSineVolleyApproachReturn
Boss_BugmaxFinishSineVolleyApproach:                    ; CODE XREF: Boss_BugmaxApproachSineVolleyTarget+12   j  ; was: loc_4D170
                                        ; Boss_BugmaxApproachSineVolleyTarget+1A   j
                move.w  #8,$48(a5)
                clr.b   (SharedScratchLong6+1).w
                bset    #1,(SharedScratchLong6+1).w
                addq.w  #2,4(a5)
Boss_BugmaxSineVolleyApproachReturn:                    ; CODE XREF: Boss_BugmaxApproachSineVolleyTarget+20   j  ; was: locret_4D184
                rts
; End of function Boss_BugmaxApproachSineVolleyTarget
; Wait eight frames and seed the sine volley count
Boss_BugmaxPrepareSineProjectileVolley:                 ; DATA XREF: ROM:0004C424   o  ; was: sub_4D186
                bsr.w   Boss_BugmaxUpdateBattleMovement
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxSineVolleyPreparationReturn
                move.w  #8,$4C(a5)
                addq.w  #2,4(a5)
Boss_BugmaxSineVolleyPreparationReturn:                 ; CODE XREF: Boss_BugmaxPrepareSineProjectileVolley+8   j  ; was: locret_4D19A
                rts
; End of function Boss_BugmaxPrepareSineProjectileVolley
; Allocate and initialize one bouncing sine projectile
Boss_BugmaxSpawnSineProjectile:                         ; DATA XREF: ROM:0004C426   o  ; was: sub_4D19C
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateVerticalBandSteering
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_BugmaxSineProjectileSpawnReturn
                bsr.w   Projectile_InitBugmaxSine
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Boss_BugmaxSineProjectileSpawnReturn:                   ; CODE XREF: Boss_BugmaxSpawnSineProjectile+E   j  ; was: locret_4D1BA
                rts
; End of function Boss_BugmaxSpawnSineProjectile
; Repeat the sine-projectile spawn for the configured volley count
Boss_BugmaxRepeatSineProjectileVolley:                  ; DATA XREF: ROM:0004C428   o  ; was: sub_4D1BC
                bsr.w   Boss_BugmaxUpdateBattleMovement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxSineVolleyRepeatReturn
                subq.w  #1,$4C(a5)
                beq.s   Boss_BugmaxFinishSineProjectileVolley
                subq.w  #2,4(a5)
Boss_BugmaxSineVolleyRepeatReturn:                      ; CODE XREF: Boss_BugmaxRepeatSineProjectileVolley+C   j  ; was: locret_4D1D4
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxFinishSineProjectileVolley:                  ; CODE XREF: Boss_BugmaxRepeatSineProjectileVolley+12   j  ; was: loc_4D1D6
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxRepeatSineProjectileVolley
; Reduce the wave step back to $0C after the sine volley
Boss_BugmaxReduceWaveStepAfterSineVolley:               ; DATA XREF: ROM:0004C42A   o  ; was: sub_4D1DC
                bsr.w   Boss_BugmaxUpdateBattleMovement
                subq.w  #1,(SharedScratchLong2).w
                cmpi.w  #$C,(SharedScratchLong2).w
                bne.s   Boss_BugmaxSineVolleyWaveReductionReturn
                addq.w  #2,4(a5)
Boss_BugmaxSineVolleyWaveReductionReturn:               ; CODE XREF: Boss_BugmaxReduceWaveStepAfterSineVolley+E   j  ; was: locret_4D1F0
                rts
; End of function Boss_BugmaxReduceWaveStepAfterSineVolley
; Return to the common battle-pattern selector
Boss_BugmaxReturnToBattlePatternSelection:              ; DATA XREF: ROM:0004C42C   o  ; was: sub_4D1F2
                bsr.w   Boss_BugmaxUpdateBattleMovement
                move.w  #$24,4(a5)                      ; '$'
                rts
; End of function Boss_BugmaxReturnToBattlePatternSelection
; Wait for the wave displacement to enter the final-transition band
Boss_BugmaxWaitForFinalWaveBand:                        ; DATA XREF: ROM:0004C42E   o  ; was: sub_4D1FE
                bsr.w   Boss_BugmaxUpdateBattleMovement
                tst.w   (SharedScratchLong0).w
                bmi.s   Boss_BugmaxFinalWaveBandWaitReturn
                cmpi.w  #$20,(SharedScratchLong0).w     ; ' '
                bgt.s   Boss_BugmaxFinalWaveBandWaitReturn
                clr.b   $21(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_BugmaxFinalWaveBandWaitReturn:                     ; CODE XREF: Boss_BugmaxWaitForFinalWaveBand+8   j  ; was: locret_4D226
                                        ; Boss_BugmaxWaitForFinalWaveBand+10   j
                rts
; End of function Boss_BugmaxWaitForFinalWaveBand
; Apply the final-transition palette pulse
Boss_BugmaxRunFinalPalettePulse:                        ; DATA XREF: ROM:0004C430   o  ; was: sub_4D228
                tst.b   (SharedScratchLong6+3).w
                bne.s   Boss_BugmaxFinishFinalPalettePulse
                subq.w  #2,$48(a5)
                bmi.s   Boss_BugmaxFinishFinalPalettePulse
                move.w  $48(a5),d0
                andi.w  #$1E,d0
                move.w  Boss_BugmaxFinalPalettePulseLevels(pc,d0.w),d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; ---------------------------------------------------------------------------
Boss_BugmaxFinalPalettePulseLevels: dc.w    0, 2, 4, 6, 8, $A, $C, $E, $E, $C, $A, 8, 6, 4, 2, 0  ; was: word_4D252
                                        ; DATA XREF: Boss_BugmaxRunFinalPalettePulse+14   r
; ---------------------------------------------------------------------------
Boss_BugmaxFinishFinalPalettePulse:                     ; CODE XREF: Boss_BugmaxRunFinalPalettePulse+4   j  ; was: loc_4D272
                                        ; Boss_BugmaxRunFinalPalettePulse+A   j
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxRunFinalPalettePulse
; Convert the primary and secondary linked-object pools into falling parts
Boss_BugmaxScatterLinkedParts:                          ; DATA XREF: ROM:0004C432   o  ; was: sub_4D27E
                subq.w  #1,$48(a5)
                bne.w   Boss_BugmaxLinkedPartScatterReturn
                move.w  #$CF80,d6
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$D,d7
Boss_BugmaxScatterPrimaryObjectPoolLoop:                ; CODE XREF: Boss_BugmaxScatterLinkedParts+3E   j  ; was: loc_4D292
                move.w  #$344,(a0)
                move.w  d6,2(a0)
                clr.b   $21(a0)
                move.w  #$FFFE,$1C(a0)
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                move.w  d0,$18(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxScatterPrimaryObjectPoolLoop
                move.w  #7,d7
                movea.w #(EighthEntityType-M68K_RAM),a0
Boss_BugmaxScatterSecondaryObjectPoolLoop:              ; CODE XREF: Boss_BugmaxScatterLinkedParts+76   j  ; was: loc_4D2C8
                move.w  #$344,(a0)
                move.w  #1,$5C(a0)
                clr.b   $21(a0)
                move.w  #$FFFE,$1C(a0)
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                move.w  d0,$18(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxScatterSecondaryObjectPoolLoop
                move.w  #$FFFA,$1C(a5)
                addq.w  #2,4(a5)
Boss_BugmaxLinkedPartScatterReturn:                     ; CODE XREF: Boss_BugmaxScatterLinkedParts+4   j  ; was: locret_4D302
                rts
; End of function Boss_BugmaxScatterLinkedParts
; Rise while emitting final particles, then relocate for the last descent
Boss_BugmaxRiseWithFinalParticles:                      ; DATA XREF: ROM:0004C434   o  ; was: sub_4D304
                cmpi.w  #$80,$14(a5)
                bgt.w   Projectile_BugmaxEmitPeriodicTrailParticle
                move.w  #$530,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                andi.w  #$7FFF,2(a5)
                clr.l   $1C(a5)
                move.w  #2,(SharedScratchLong2).w
                move.w  #$40,(SharedScratchLong3).w     ; '@'
                move.w  #$40,(SharedScratchLong3+2).w   ; '@'
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_BugmaxFinalRiseReturn
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                andi.w  #$7FFF,$E(a0)
                addq.b  #4,$20(a0)
                move.l  #SharedCombatSpriteAnimation00,8(a0)
Boss_BugmaxFinalRiseReturn:                             ; CODE XREF: Boss_BugmaxRiseWithFinalParticles+42   j  ; was: locret_4D372
                rts
; End of function Boss_BugmaxRiseWithFinalParticles
; Wait before accelerating into the final descent
Boss_BugmaxWaitBeforeFinalDescent:                      ; DATA XREF: ROM:0004C436   o  ; was: sub_4D374
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxFinalDescentWaitReturn
                addq.w  #2,4(a5)
Boss_BugmaxFinalDescentWaitReturn:                      ; CODE XREF: Boss_BugmaxWaitBeforeFinalDescent+4   j  ; was: locret_4D37E
                rts
; End of function Boss_BugmaxWaitBeforeFinalDescent
; Accelerate downward until the final descent threshold
Boss_BugmaxAccelerateFinalDescent:                      ; DATA XREF: ROM:0004C438   o  ; was: sub_4D380
                addi.l  #$800,$1C(a5)
                cmpi.l  #$8000,$1C(a5)
                bcs.s   Boss_BugmaxFinalDescentAccelerationReturn
                move.w  #$5C,(MessageSequenceState).w   ; '\'
                addq.w  #2,4(a5)
Boss_BugmaxFinalDescentAccelerationReturn:              ; CODE XREF: Boss_BugmaxAccelerateFinalDescent+10   j  ; was: locret_4D39C
                rts
; End of function Boss_BugmaxAccelerateFinalDescent
; Apply wave-driven descent and complete the encounter below screen Y $170
Boss_BugmaxUpdateFinalWaveDescentAndCompleteEncounter:  ; DATA XREF: ROM:0004C43A   o  ; was: sub_4D39E
                bsr.w   Boss_BugmaxUpdateWaveDisplacement
                move.l  (SharedScratchLong0).w,d0
                asr.l   #4,d0
                move.l  d0,$18(a5)
                cmpi.w  #$170,$14(a5)
                blt.s   Boss_BugmaxFinalWaveDescentReturn
                move.b  #1,(SoundFadeOutDelay).w
                clr.w   (a5)
                move.w  #$1000,2(a5)
Boss_BugmaxFinalWaveDescentReturn:                      ; CODE XREF: Boss_BugmaxUpdateFinalWaveDescentAndCompleteEncounter+14   j  ; was: locret_4D3C2
                rts
; End of function Boss_BugmaxUpdateFinalWaveDescentAndCompleteEncounter
