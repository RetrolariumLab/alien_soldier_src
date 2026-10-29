Projectile_Epsilon1ConvertOnGlobalMode:                 ; CODE XREF: Projectile_Epsilon1SpreadProjectileMain   p  ; was: sub_477D8
                                        ; Projectile_Epsilon1BarrageEmitterMain   p
                btst    #0,(PrimaryEntityWork4C).w
                bne.s   Projectile_Epsilon1ConvertToType88
                btst    #2,(PrimaryEntityWork4C).w
                beq.s   Projectile_Epsilon1GlobalModeReturn
Projectile_Epsilon1ConvertToType88:                     ; CODE XREF: Projectile_Epsilon1ConvertOnGlobalMode+6   j  ; was: loc_477E8
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_Epsilon1GlobalModeReturn:                    ; CODE XREF: Projectile_Epsilon1ConvertOnGlobalMode+E   j  ; was: locret_477F6
                rts
; End of function Projectile_Epsilon1ConvertOnGlobalMode
; Applies a quadrant-signed vertical step selected by the caller's direction flag
Boss_Epsilon1ApplyDirectionalVerticalStep:              ; CODE XREF: Boss_Epsilon1MoveToUpperSweepHeightState   p  ; was: sub_477F8
                                        ; Boss_Epsilon1RecoverBattleCenterState:Boss_Epsilon1MoveToRecoveryHeight   p
                                        ; Boss_Epsilon1ReturnToUpperBoundaryState   p
                move.w  (SharedScratchLong5).w,d0
                addi.w  #$40,d0                         ; '@'
                andi.w  #$180,d0
                lsr.w   #6,d0
                move.w  Boss_Epsilon1VerticalStepSigns(pc,d0.w),d0
                move.w  (SharedScratchLong4).w,d1
                muls.w  d0,d1
                cmpi.w  #0,$58(a5)
                bne.s   Boss_Epsilon1CheckPositiveVerticalStep
                tst.w   d0
                bpl.s   Boss_Epsilon1VerticalStepReturn
                bra.s   Boss_Epsilon1AddVerticalStep
; ---------------------------------------------------------------------------
Boss_Epsilon1CheckPositiveVerticalStep:                 ; CODE XREF: Boss_Epsilon1ApplyDirectionalVerticalStep+1E   j  ; was: loc_4781E
                tst.w   d0
                bpl.s   Boss_Epsilon1AddVerticalStep
Boss_Epsilon1VerticalStepReturn:                        ; CODE XREF: Boss_Epsilon1ApplyDirectionalVerticalStep+22   j  ; was: locret_47822
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1AddVerticalStep:                           ; CODE XREF: Boss_Epsilon1ApplyDirectionalVerticalStep+24   j  ; was: loc_47824
                                        ; Boss_Epsilon1ApplyDirectionalVerticalStep+28   j
                add.l   d1,(SecondaryEntityYPos).w
                rts
; End of function Boss_Epsilon1ApplyDirectionalVerticalStep
; ---------------------------------------------------------------------------
Boss_Epsilon1VerticalStepSigns: dc.w    $4000, $4000, $C000, $C000  ; was: word_4782A
                                        ; DATA XREF: Boss_Epsilon1ApplyDirectionalVerticalStep+E   r

; Selects vertical motion, steers horizontal acceleration, and integrates the battle center
Boss_Epsilon1UpdateBattleCenterMotion:                  ; CODE XREF: Boss_Epsilon1BeginSpreadRingAttackState   p  ; was: sub_47832
                                        ; Boss_Epsilon1WaitForSpreadAttackAngleWrapState   p
                                        ; Boss_Epsilon1BeginRingCycleAttackState   p
                                        ; Boss_Epsilon1WaitForRingCycleAngleWrapState   p
                                        ; Boss_Epsilon1WaitForRingCycleCompleteState   p
                                        ; Boss_Epsilon1BeginVerticalSweepAttackState   p
                                        ; Boss_Epsilon1WaitForVerticalSweepAngleWrapState   p
                cmpi.w  #$80,(SecondaryEntityYPos).w
                bcs.s   Boss_Epsilon1SelectPositiveVerticalStep
                cmpi.w  #$E0,(SecondaryEntityYPos).w
                bhi.s   Boss_Epsilon1SelectNegativeVerticalStep
                move.b  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Boss_Epsilon1ApplyBattleCenterVerticalStep
                move.b  (RandomNumberState+1).w,d0
                andi.b  #1,d0
                beq.s   Boss_Epsilon1SelectNegativeVerticalStep
Boss_Epsilon1SelectPositiveVerticalStep:                ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+6   j  ; was: loc_47856
                move.w  #1,$58(a5)
                bra.s   Boss_Epsilon1ApplyBattleCenterVerticalStep
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectNegativeVerticalStep:                ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+E   j  ; was: loc_4785E
                                        ; Boss_Epsilon1UpdateBattleCenterMotion+22   j
                move.w  #0,$58(a5)
Boss_Epsilon1ApplyBattleCenterVerticalStep:             ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+18   j  ; was: loc_47864
                                        ; Boss_Epsilon1UpdateBattleCenterMotion+2A   j
                bsr.w   Boss_Epsilon1ApplyDirectionalVerticalStep
                cmpi.w  #0,$58(a5)
                beq.w   Boss_Epsilon1RetargetHorizontalAcceleration
                move.w  (FrameCounter).w,d7
                andi.w  #3,d7
                bne.s   Boss_Epsilon1IntegrateBattleCenterHorizontalMotion
Boss_Epsilon1RetargetHorizontalAcceleration:            ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+3C   j  ; was: loc_4787C
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d0
                beq.s   Boss_Epsilon1IntegrateBattleCenterHorizontalMotion
                tst.w   d1
                bpl.s   Boss_Epsilon1AccelerateBattleCenterRight
Boss_Epsilon1AccelerateBattleCenterLeft:                ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+78   j  ; was: loc_4788A
                move.l  #$FFFFC000,(SecondaryEntityWork5C).w
                bra.s   Boss_Epsilon1IntegrateBattleCenterHorizontalMotion
; ---------------------------------------------------------------------------
Boss_Epsilon1AccelerateBattleCenterRight:               ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+56   j  ; was: loc_47894
                                        ; Boss_Epsilon1UpdateBattleCenterMotion+80   j
                move.l  #$4000,(SecondaryEntityWork5C).w
Boss_Epsilon1IntegrateBattleCenterHorizontalMotion:     ; CODE XREF: Boss_Epsilon1UpdateBattleCenterMotion+48   j  ; was: loc_4789C
                                        ; Boss_Epsilon1UpdateBattleCenterMotion+52   j
                move.l  (SecondaryEntityWork5C).w,d0
                add.l   (SecondaryEntityWork58).w,d0
                cmpi.l  #$20000,d0
                bge.s   Boss_Epsilon1AccelerateBattleCenterLeft
                cmpi.l  #$FFFE0000,d0
                ble.s   Boss_Epsilon1AccelerateBattleCenterRight
                move.l  d0,(SecondaryEntityWork58).w
                move.l  (SecondaryEntityWork58).w,d0
                add.l   d0,(SecondaryEntityXPos).w
                rts
; End of function Boss_Epsilon1UpdateBattleCenterMotion
; Advances the Epsilon 1 palette-color cycle once every four frames
Boss_Epsilon1CyclePaletteColor:                         ; CODE XREF: Boss_Epsilon1Main+16E   p  ; was: sub_478C2
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_Epsilon1CyclePaletteColorReturn
                move.w  $52(a5),d0
                add.w   d0,d0
                move.w  Boss_Epsilon1PaletteColorCycle(pc,d0.w),(PaletteActiveColor62).w
                addq.w  #1,$52(a5)
                cmpi.w  #$E,$52(a5)
                bne.s   Boss_Epsilon1CyclePaletteColorReturn
                clr.w   $52(a5)
Boss_Epsilon1CyclePaletteColorReturn:                   ; CODE XREF: Boss_Epsilon1CyclePaletteColor+8   j  ; was: locret_478E8
                                        ; Boss_Epsilon1CyclePaletteColor+20   j
                rts
; End of function Boss_Epsilon1CyclePaletteColor
; ---------------------------------------------------------------------------
Boss_Epsilon1PaletteColorCycle: dc.w    $E, $C, $A, 8, 6, 4, 2, 0, 2, 4, 6, 8, $A, $C  ; was: word_478EA
                                        ; DATA XREF: Boss_Epsilon1CyclePaletteColor+10   r

; Builds the twenty-word horizontal-scroll profile and six rotating-row samples
Boss_Epsilon1BuildScrollProfile:                        ; CODE XREF: Boss_Epsilon1Main+B0   p  ; was: sub_47906
                lea     (VerticalScrollProfile).w,a1
                move.w  #$13,d7
                move.w  #$30,d0                         ; '0'
Boss_Epsilon1InitializeScrollProfileLoop:               ; CODE XREF: Boss_Epsilon1BuildScrollProfile+E   j  ; was: loc_47912
                move.w  d0,(a1)+
                dbf     d7,Boss_Epsilon1InitializeScrollProfileLoop
                move.w  (SecondaryCameraYPos).w,d2
                lea     (VerticalScrollProfile).w,a1
                lea     (Math_SineTable).l,a2
                lea     (SharedScratchLong11).w,a3
                lea     (Epsilon1RowOffsetTable).w,a4
                move.w  (SecondaryEntityXPos).w,d6
                subi.w  #$40,d6                         ; '@'
                move.w  #7,d7
Boss_Epsilon1WriteCenterYToScrollProfileLoop:           ; CODE XREF: Boss_Epsilon1BuildScrollProfile+50   j  ; was: loc_4793A
                move.w  d6,d1
                subi.w  #$80,d1
                bmi.s   Boss_Epsilon1AdvanceCenterScrollSpan
                cmpi.w  #$140,d1
                bhi.s   Boss_Epsilon1AdvanceCenterScrollSpan
                andi.w  #$1F0,d1
                lsr.w   #3,d1
                move.w  d2,(a1,d1.w)
Boss_Epsilon1AdvanceCenterScrollSpan:                   ; CODE XREF: Boss_Epsilon1BuildScrollProfile+3A   j  ; was: loc_47952
                                        ; Boss_Epsilon1BuildScrollProfile+40   j
                addi.w  #$10,d6
                dbf     d7,Boss_Epsilon1WriteCenterYToScrollProfileLoop
                move.w  d2,d3
                subq.w  #8,d3
                move.w  #5,d7
                lea     (SharedScratchLong0).w,a0
                move.w  (SecondaryEntityXPos).w,d5
                move.w  d5,d6
                subi.w  #$60,d5                         ; '`'
                addi.w  #$40,d6                         ; '@'
Boss_Epsilon1WriteRotatingShapeToScrollProfileLoop:     ; CODE XREF: Boss_Epsilon1BuildScrollProfile+102   j  ; was: loc_47974
                move.w  (a0)+,d0
                move.w  -$80(a2,d0.w),d0
                ext.l   d0
                asl.l   #6,d0
                swap    d0
                add.w   d0,d3
                add.w   (a4)+,d3
                cmpi.w  #$120,d3
                bgt.s   Boss_Epsilon1StoreRotatingShapeRowSample
                cmpi.w  #$48,d3                         ; 'H'
                blt.s   Boss_Epsilon1StoreRotatingShapeRowSample
                move.w  d5,d1
                subi.w  #$80,d1
                bmi.s   Boss_Epsilon1CheckAdjacentLeftProfileColumn
                cmpi.w  #$140,d1
                bgt.s   Boss_Epsilon1CheckAdjacentLeftProfileColumn
                andi.w  #$1F0,d1
                lsr.w   #3,d1
                move.w  d3,(a1,d1.w)
Boss_Epsilon1CheckAdjacentLeftProfileColumn:            ; CODE XREF: Boss_Epsilon1BuildScrollProfile+90   j  ; was: loc_479A8
                                        ; Boss_Epsilon1BuildScrollProfile+96   j
                move.w  d5,d1
                addi.w  #$10,d1
                subi.w  #$80,d1
                bmi.s   Boss_Epsilon1CheckRightProfileColumn
                cmpi.w  #$140,d1
                bgt.s   Boss_Epsilon1CheckRightProfileColumn
                andi.w  #$1F0,d1
                lsr.w   #3,d1
                move.w  d3,(a1,d1.w)
Boss_Epsilon1CheckRightProfileColumn:                   ; CODE XREF: Boss_Epsilon1BuildScrollProfile+AC   j  ; was: loc_479C4
                                        ; Boss_Epsilon1BuildScrollProfile+B2   j
                move.w  d6,d1
                subi.w  #$80,d1
                bmi.s   Boss_Epsilon1CheckAdjacentRightProfileColumn
                cmpi.w  #$140,d1
                bgt.s   Boss_Epsilon1CheckAdjacentRightProfileColumn
                andi.w  #$1F0,d1
                lsr.w   #3,d1
                move.w  d3,(a1,d1.w)
Boss_Epsilon1CheckAdjacentRightProfileColumn:           ; CODE XREF: Boss_Epsilon1BuildScrollProfile+C4   j  ; was: loc_479DC
                                        ; Boss_Epsilon1BuildScrollProfile+CA   j
                move.w  d6,d1
                addi.w  #$10,d1
                subi.w  #$80,d1
                bmi.s   Boss_Epsilon1StoreRotatingShapeRowSample
                cmpi.w  #$140,d1
                bgt.s   Boss_Epsilon1StoreRotatingShapeRowSample
                andi.w  #$1F0,d1
                lsr.w   #3,d1
                move.w  d3,(a1,d1.w)
Boss_Epsilon1StoreRotatingShapeRowSample:               ; CODE XREF: Boss_Epsilon1BuildScrollProfile+82   j  ; was: loc_479F8
                                        ; Boss_Epsilon1BuildScrollProfile+88   j
                subi.w  #$20,d5                         ; ' '
                addi.w  #$20,d6                         ; ' '
                move.w  d3,(a3)
                move.w  d3,$C(a3)
                addq.w  #2,a3
                dbf     d7,Boss_Epsilon1WriteRotatingShapeToScrollProfileLoop
                rts
; End of function Boss_Epsilon1BuildScrollProfile
; Streams or clears four tile bands from their screen-space visibility
Boss_Epsilon1UpdateVisibleTileBands:                    ; CODE XREF: Boss_Epsilon1Main+B4   p  ; was: sub_47A0E
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_Epsilon1TileStreamingReturn
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                tst.w   d0
                beq.s   Boss_Epsilon1SelectVisibleTileBands
                cmpi.w  #$70,4(a5)                      ; 'p'
                bcc.w   Boss_Epsilon1TileStreamingReturn
                cmpi.w  #1,d0
                beq.w   Boss_Epsilon1SelectAnimatedTilePair0
                cmpi.w  #2,d0
                beq.w   Boss_Epsilon1SelectAnimatedTilePair1
                cmpi.w  #3,d0
                beq.w   Boss_Epsilon1SelectAnimatedTilePair2
Boss_Epsilon1SelectVisibleTileBands:                    ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+12   j  ; was: loc_47A44
                cmpi.w  #$180,(SecondaryCameraXPos).w
                bgt.s   Boss_Epsilon1ClearAllTileBands
                cmpi.w  #$FF80,(SecondaryCameraXPos).w
                blt.w   Boss_Epsilon1ClearAllTileBands
                cmpi.w  #$20,(SecondaryCameraYPos).w    ; ' '
                blt.s   Boss_Epsilon1ClearFirstTileBand
                cmpi.w  #$120,(SecondaryCameraYPos).w
                bgt.s   Boss_Epsilon1ClearFirstTileBand
                bsr.w   Gfx_LoadEpsilon1TileBand1
                bra.s   Boss_Epsilon1SelectSecondTileBand
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearFirstTileBand:                        ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+4E   j  ; was: loc_47A6C
                                        ; Boss_Epsilon1UpdateVisibleTileBands+56   j
                bsr.w   Gfx_ClearEpsilon1TileBand1
Boss_Epsilon1SelectSecondTileBand:                      ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+5C   j  ; was: loc_47A70
                cmpi.w  #$40,(SecondaryCameraYPos).w    ; '@'
                blt.s   Boss_Epsilon1ClearSecondTileBand
                cmpi.w  #$140,(SecondaryCameraYPos).w
                bgt.s   Boss_Epsilon1ClearSecondTileBand
                bsr.w   Gfx_LoadEpsilon1TileBand2
                bra.s   Boss_Epsilon1SelectThirdTileBand
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearSecondTileBand:                       ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+68   j  ; was: loc_47A86
                                        ; Boss_Epsilon1UpdateVisibleTileBands+70   j
                bsr.w   Gfx_ClearEpsilon1TileBand2
Boss_Epsilon1SelectThirdTileBand:                       ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+76   j  ; was: loc_47A8A
                cmpi.w  #$60,(SecondaryCameraYPos).w    ; '`'
                blt.s   Boss_Epsilon1ClearThirdTileBand
                cmpi.w  #$160,(SecondaryCameraYPos).w
                bgt.s   Boss_Epsilon1ClearThirdTileBand
                bsr.w   Gfx_LoadEpsilon1TileBand3
                bra.s   Boss_Epsilon1SelectFourthTileBand
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearThirdTileBand:                        ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+82   j  ; was: loc_47AA0
                                        ; Boss_Epsilon1UpdateVisibleTileBands+8A   j
                bsr.w   Gfx_ClearEpsilon1TileBand3
Boss_Epsilon1SelectFourthTileBand:                      ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+90   j  ; was: loc_47AA4
                cmpi.w  #$80,(SecondaryCameraYPos).w
                blt.s   Boss_Epsilon1ClearFourthTileBand
                cmpi.w  #$180,(SecondaryCameraYPos).w
                bgt.s   Boss_Epsilon1ClearFourthTileBand
                bsr.w   Gfx_LoadEpsilon1TileBand4
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearFourthTileBand:                       ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+9C   j  ; was: loc_47ABA
                                        ; Boss_Epsilon1UpdateVisibleTileBands+A4   j
                bsr.w   Gfx_ClearEpsilon1TileBand4
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearAllTileBands:                         ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+3C   j  ; was: loc_47AC0
                                        ; Boss_Epsilon1UpdateVisibleTileBands+44   j
                bsr.w   Gfx_ClearEpsilon1TileBand1
                bsr.w   Gfx_ClearEpsilon1TileBand2
                bsr.w   Gfx_ClearEpsilon1TileBand3
                bsr.w   Gfx_ClearEpsilon1TileBand4
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectAnimatedTilePair0:                   ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+22   j  ; was: loc_47AD2
                move.w  #0,(Epsilon1TileBandIndex).w
                bra.s   Boss_Epsilon1QueueAnimatedTilePair
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectAnimatedTilePair1:                   ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+2A   j  ; was: loc_47ADA
                move.w  #2,(Epsilon1TileBandIndex).w
                bra.s   Boss_Epsilon1QueueAnimatedTilePair
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectAnimatedTilePair2:                   ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+32   j  ; was: loc_47AE2
                move.w  #4,(Epsilon1TileBandIndex).w
Boss_Epsilon1QueueAnimatedTilePair:                     ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+CA   j  ; was: loc_47AE8
                                        ; Boss_Epsilon1UpdateVisibleTileBands+D2   j
                move.w  #2,(SharedScratchLong6).w
Boss_Epsilon1QueueAnimatedTilePairLoop:                 ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+F6   j  ; was: loc_47AEE
                move.w  (Epsilon1TileBandIndex).w,d0
                bsr.s   Boss_Epsilon1QueueAnimatedTileTransfer
                move.w  (Epsilon1TileBandIndex).w,d0
                addq.w  #6,d0
                bsr.s   Boss_Epsilon1QueueAnimatedTileTransfer
                addq.w  #1,(Epsilon1TileBandIndex).w
                subq.w  #1,(SharedScratchLong6).w
                bne.s   Boss_Epsilon1QueueAnimatedTilePairLoop
Boss_Epsilon1TileStreamingReturn:                       ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+4   j  ; was: locret_47B06
                                        ; Boss_Epsilon1UpdateVisibleTileBands+1A   j
                rts
; End of function Boss_Epsilon1UpdateVisibleTileBands
; Builds and submits one animated tile-transfer descriptor
Boss_Epsilon1QueueAnimatedTileTransfer:                 ; CODE XREF: Boss_Epsilon1UpdateVisibleTileBands+E4   p  ; was: sub_47B08
                                        ; Boss_Epsilon1UpdateVisibleTileBands+EC   p
                lea     (Epsilon1TileDMARecord).w,a0
                add.w   d0,d0
                move.w  #$4000,d1
                add.w   Boss_Epsilon1AnimatedTileDestinations(pc,d0.w),d1
                move.w  d1,(a0)
                move.w  #$2000,2(a0)
                move.w  #1,4(a0)
                lea     (Epsilon1RingPhaseTable).w,a1
                move.w  (a1,d0.w),d1
                bne.s   Boss_Epsilon1SelectAnimatedTileFrame
                cmpi.w  #$C,d0
                bcs.s   Boss_Epsilon1UseRotationSampleForTileFrame
                subi.w  #$C,d0
Boss_Epsilon1UseRotationSampleForTileFrame:             ; CODE XREF: Boss_Epsilon1QueueAnimatedTileTransfer+2A   j  ; was: loc_47B38
                lea     (SharedScratchLong0).w,a1
                move.w  (a1,d0.w),d1
Boss_Epsilon1SelectAnimatedTileFrame:                   ; CODE XREF: Boss_Epsilon1QueueAnimatedTileTransfer+24   j  ; was: loc_47B40
                addi.w  #$10,d1
                andi.w  #$1E0,d1
                lsr.w   #4,d1
                move.w  Boss_Epsilon1AnimatedTileFrames(pc,d1.w),6(a0)
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_Epsilon1QueueAnimatedTileTransfer
; ---------------------------------------------------------------------------
Boss_Epsilon1AnimatedTileDestinations:  dc.w    $1A8, $1A0, $198, $190, $188, $180, $1D0, $1D8, $1E0, $1E8, $1F0, $1F8  ; was: word_47B56
                                        ; DATA XREF: Boss_Epsilon1QueueAnimatedTileTransfer+A   r
Boss_Epsilon1AnimatedTileFrames:    dc.w    $989C, $999D, $9A9E, $9B9F, $A0A4, $A0A4, $A0A4, $A0A4, $A0A4, $9B9F, $9A9E, $999D, $989C, $989C, $989C, $989C  ; was: word_47B6E
                                        ; DATA XREF: Boss_Epsilon1QueueAnimatedTileTransfer+42   r

; Intro controller state dispatcher
Boss_Epsilon1IntroController:                           ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_47B8E
                move.w  4(a5),d0
                lea     Boss_Epsilon1IntroControllerStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1IntroController
; ---------------------------------------------------------------------------
Boss_Epsilon1IntroControllerStates: dc.w    Boss_Epsilon1SpawnIntroProjectileState-*  ; DATA XREF: Boss_Epsilon1IntroController+4   o ; was: off_47B9A
                dc.w    Boss_Epsilon1ActivateIntroProjectileState-*
                dc.w    Boss_Epsilon1AdvanceIntroCycleState-*
                dc.w    Boss_Epsilon1IntroCompletionDelayState-*

; Spawns the type-$278 intro object and initializes a two-cycle counter
Boss_Epsilon1SpawnIntroProjectileState:                 ; DATA XREF: ROM:Boss_Epsilon1IntroControllerStates   o  ; was: sub_47BA2
                tst.b   (MessageSequenceState).w
                bne.s   Boss_Epsilon1SpawnIntroProjectileReturn
                addq.w  #2,4(a5)
                move.w  #2,$4A(a5)
                movea.w #(FifthEntityType-M68K_RAM),a0
                move.w  #$278,(a0)
                move.w  #$C3C0,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.w  #$C80,2(a0)
Boss_Epsilon1SpawnIntroProjectileReturn:                ; CODE XREF: Boss_Epsilon1SpawnIntroProjectileState+4   j  ; was: locret_47BD2
                rts
; End of function Boss_Epsilon1SpawnIntroProjectileState
; Activates the waiting intro object after its state returns to zero
Boss_Epsilon1ActivateIntroProjectileState:              ; DATA XREF: ROM:00047B9C   o  ; was: sub_47BD4
                tst.w   (FifthEntityState).w
                bne.s   Boss_Epsilon1ActivateIntroProjectileReturn
                move.w  #1,(FifthEntityWork5E).w
                addq.w  #2,(FifthEntityState).w
                addq.w  #2,4(a5)
Boss_Epsilon1ActivateIntroProjectileReturn:             ; CODE XREF: Boss_Epsilon1ActivateIntroProjectileState+4   j  ; was: locret_47BE8
                rts
; End of function Boss_Epsilon1ActivateIntroProjectileState
; Repeats the intro object cycle twice, then starts the completion delay
Boss_Epsilon1AdvanceIntroCycleState:                    ; DATA XREF: ROM:00047B9E   o  ; was: sub_47BEA
                cmpi.w  #$C,(FifthEntityState).w
                bne.s   Boss_Epsilon1AdvanceIntroCycleReturn
                addq.w  #2,(FifthEntityState).w
                subq.w  #1,$4A(a5)
                beq.s   Boss_Epsilon1StartIntroCompletionDelay
                subq.w  #2,4(a5)
Boss_Epsilon1AdvanceIntroCycleReturn:                   ; CODE XREF: Boss_Epsilon1AdvanceIntroCycleState+6   j  ; was: locret_47C00
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1StartIntroCompletionDelay:                 ; CODE XREF: Boss_Epsilon1AdvanceIntroCycleState+10   j  ; was: loc_47C02
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1AdvanceIntroCycleState
; Marks the controller complete after its final delay
Boss_Epsilon1IntroCompletionDelayState:                 ; DATA XREF: ROM:00047BA0   o  ; was: sub_47C0E
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1IntroCompletionDelayReturn
                move.w  #$1000,2(a5)
Boss_Epsilon1IntroCompletionDelayReturn:                ; CODE XREF: Boss_Epsilon1IntroCompletionDelayState+4   j  ; was: locret_47C1A
                rts
; End of function Boss_Epsilon1IntroCompletionDelayState
; Main Sharpsteel boss handler
