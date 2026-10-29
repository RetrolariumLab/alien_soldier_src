Cutscene_DispatchPlanetGrid:
                move.w  (PlanetGridState).l,d0          ; was: sub_5150
                lea     Cutscene_PlanetGridStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Cutscene_DispatchPlanetGrid
; ---------------------------------------------------------------------------
Cutscene_PlanetGridStates:  dc.w    Cutscene_StartPlanetGrid-*  ; was: off_515E
                dc.w    Cutscene_SetupFirstPlanetGrid-*
                dc.w    Cutscene_EraseFirstPlanetGrid-*
                dc.w    Cutscene_HoldFirstPlanetGrid-*
                dc.w    Cutscene_RevealFirstPlanetGrid-*
                dc.w    Cutscene_RevealFirstPlanetGrid-*
                dc.w    Cutscene_SetupSecondPlanetGrid-*
                dc.w    Cutscene_EraseSecondPlanetGrid-*
                dc.w    Cutscene_UpdateSecondPlanetGrid-*
                dc.w    Cutscene_RevealSecondPlanetGrid-*
                dc.w    Cutscene_PlanetGridSequenceComplete-*

; Starts the planet-grid controller with a one-frame setup delay
Cutscene_StartPlanetGrid:                               ; was: sub_5174
                move.w  #1,(PlanetGridTimer).l
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_StartPlanetGrid
; Configures the first 2-by-4 planet sprite grid and its pattern buffer
Cutscene_SetupFirstPlanetGrid:                          ; was: sub_5184
                subq.w  #1,(PlanetGridTimer).l
                bne.w   Cutscene_Return
                lea     (EleventhEntityType).w,a5
                move.w  #$CC00,EleventhEntityFlags-EleventhEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneFirstPlanetGridSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$C0,$10(a5)
                move.w  #$120,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$4E0,(SpriteGridFirstTile).l
                move.w  #$120,(SpriteGridCenterY).l
                move.w  #$C0,(SpriteGridCenterX).l
                move.w  #1,(SpriteGridRowLimit).l
                move.w  #3,(SpriteGridColumnLimit).l
                move.l  #$5C000002,(PatternVDPCommand).l
                move.w  #$F,(PlanetPatternWriteOnly).l
                move.w  #3,(PatternFrameMask).l
                clr.w   (PatternDissolveStep).l
                jsr     Cutscene_FillPlanetPattern(pc)  ; (pc)
                nop
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_SetupFirstPlanetGrid
; Accelerates the first grid horizontally while erasing pattern nibbles
Cutscene_EraseFirstPlanetGrid:                          ; was: sub_5214
                addi.l  #$80,(EleventhEntityXVel).w
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_ErasePlanetPatternStep
                bsr.w   Cutscene_QueuePlanetPatternRows
                cmpi.w  #$40,(PatternDissolveStep).l    ; '@'
                bne.w   Cutscene_Return
                move.w  #$80,(PlanetGridTimer).l
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_EraseFirstPlanetGrid
; Keeps the first grid visible until its hold timer expires
Cutscene_HoldFirstPlanetGrid:                           ; was: sub_5244
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_QueuePlanetPatternRows
                subq.w  #1,(PlanetGridTimer).l
                bne.w   Cutscene_Return
; End of function Cutscene_HoldFirstPlanetGrid
; Shared fall-through tail that advances the planet-grid state
Cutscene_AdvancePlanetGridState:
                addq.w  #2,(PlanetGridState).l          ; was: sub_5256
                rts
; End of function Cutscene_AdvancePlanetGridState
; Reverses the first grid's horizontal motion while restoring its pattern
Cutscene_RevealFirstPlanetGrid:                         ; was: sub_525E
                                        ; ROM:00005168   o
                subi.l  #$80,(EleventhEntityXVel).w
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_RevealPlanetPatternStep
                bsr.w   Cutscene_QueuePlanetPatternRows
                tst.w   (PatternDissolveStep).l
                bpl.w   Cutscene_Return
                clr.l   (EleventhEntityXVel).w
                move.w  #$100,(PlanetGridTimer).l
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_RevealFirstPlanetGrid
; Reconfigures the object as the second 4-by-2 planet grid
Cutscene_SetupSecondPlanetGrid:                         ; was: sub_5290
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_QueuePlanetPatternRows
                subq.w  #1,(PlanetGridTimer).l
                bne.w   Cutscene_Return
                lea     (EleventhEntityType).w,a5
                move.w  #$CC00,EleventhEntityFlags-EleventhEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneSecondPlanetGridSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$180,$10(a5)
                move.w  #$120,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                andi.w  #$7FFF,(EleventhEntityFlags).w
                move.w  #$4E0,(SpriteGridFirstTile).l
                move.w  #$120,(SpriteGridCenterY).l
                move.w  #$180,(SpriteGridCenterX).l
                move.w  #3,(SpriteGridRowLimit).l
                move.w  #1,(SpriteGridColumnLimit).l
                move.l  #$5C000002,(PatternVDPCommand).l
                move.w  #$F,(PlanetPatternWriteOnly).l
                move.w  #3,(PatternFrameMask).l
                clr.w   (PatternDissolveStep).l
                jsr     Cutscene_FillPlanetPattern(pc)  ; (pc)
                nop
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_SetupSecondPlanetGrid
; Accelerates the second grid vertically while erasing pattern nibbles
Cutscene_EraseSecondPlanetGrid:                         ; was: sub_532E
                ori.w   #$8000,(EleventhEntityFlags).w
                subi.l  #$40,(EleventhEntityYVel).w     ; '@'
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_ErasePlanetPatternStep
                bsr.w   Cutscene_QueuePlanetPatternRows
                cmpi.w  #$40,(PatternDissolveStep).l    ; '@'
                bne.w   Cutscene_Return
; End of function Cutscene_EraseSecondPlanetGrid
; Starts the second grid's $80-frame hold and advances its state
Cutscene_StartSecondPlanetGridHold:
                move.w  #$80,(PlanetGridTimer).l        ; was: sub_5354
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_StartSecondPlanetGridHold
; Refreshes the second grid before entering the timer fall-through
Cutscene_UpdateSecondPlanetGrid:                        ; was: sub_5364
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_QueuePlanetPatternRows
; End of function Cutscene_UpdateSecondPlanetGrid
; Waits for the second grid's hold timer and advances its state
Cutscene_WaitSecondPlanetGridHold:
                subq.w  #1,(PlanetGridTimer).l          ; was: sub_536C
                bne.w   Cutscene_Return
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_WaitSecondPlanetGridHold
; Reverses the second grid's vertical motion while restoring its pattern
Cutscene_RevealSecondPlanetGrid:                        ; was: sub_537E
                addi.l  #$40,(EleventhEntityYVel).w     ; '@'
                bsr.w   Cutscene_CopyPlanetGridCenter
                bsr.w   Cutscene_RevealPlanetPatternStep
                bsr.w   Cutscene_QueuePlanetPatternRows
                tst.w   (PatternDissolveStep).l
                bpl.w   Cutscene_Return
                clr.w   (EleventhEntityFlags).w
                addq.w  #2,(PlanetGridState).l
                rts
; End of function Cutscene_RevealSecondPlanetGrid
Cutscene_PlanetGridSequenceComplete:                    ; was: nullsub_15
                rts
; End of function Cutscene_PlanetGridSequenceComplete

; Dispatches the independent ship-grid sequence
Cutscene_DispatchShipGrid:
                move.w  (ShipGridState).l,d0            ; was: sub_53AA
                lea     Cutscene_ShipGridStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Cutscene_DispatchShipGrid
; ---------------------------------------------------------------------------
Cutscene_ShipGridStates:    dc.w    Cutscene_StartFirstShipGridDelay-*  ; was: off_53B8
                dc.w    Cutscene_SetupFirstShipGrid-*
                dc.w    Cutscene_EraseFirstShipGrid-*
                dc.w    Cutscene_HoldFirstShipGrid-*
                dc.w    Cutscene_RevealFirstShipGrid-*
                dc.w    Cutscene_SetupSecondShipGrid-*
                dc.w    Cutscene_EraseSecondShipGrid-*
                dc.w    Cutscene_HoldSecondShipGrid-*
                dc.w    Cutscene_RevealSecondShipGrid-*
                dc.w    Cutscene_ShipGridSequenceComplete-*

; Starts the delay before the first ship grid is configured
Cutscene_StartFirstShipGridDelay:                       ; was: sub_53CC
                move.w  #$100,(ShipGridTimer).l
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_StartFirstShipGridDelay
; Configures the first 2-by-4 ship sprite grid and its pattern buffer
Cutscene_SetupFirstShipGrid:                            ; was: sub_53DC
                subq.w  #1,(ShipGridTimer).l
                bne.w   Cutscene_Return
                lea     (TwelfthEntityType).w,a5
                move.w  #$CC00,TwelfthEntityFlags-TwelfthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneFirstShipGridSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$180,$10(a5)
                move.w  #$C0,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$4F0,(ShipGridFirstTile).l
                move.w  #$C0,(ShipGridCenterY).l
                move.w  #$180,(ShipGridCenterX).l
                move.w  #1,(ShipGridRowLimit).l
                move.w  #3,(ShipGridColumnLimit).l
                move.l  #$5E000002,(ShipPatternVDPCommand).l
                move.w  #$F,(ShipPatternWriteOnly).l
                move.w  #3,(ShipPatternFrameMask).l
                clr.w   (ShipPatternStep).l
                jsr     Cutscene_FillShipPattern(pc)    ; (pc)
                nop
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_SetupFirstShipGrid
; Changes horizontal velocity while erasing the first ship-grid pattern
Cutscene_EraseFirstShipGrid:                            ; was: sub_546C
                subi.l  #$80,(TwelfthEntityXVel).w
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_EraseShipPatternStep
                bsr.w   Cutscene_QueueShipPatternRows
                cmpi.w  #$40,(ShipPatternStep).l        ; '@'
                bne.w   Cutscene_Return
                move.w  #$80,(ShipGridTimer).l
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_EraseFirstShipGrid
; Keeps the first ship grid visible until its hold timer expires
Cutscene_HoldFirstShipGrid:                             ; was: sub_549C
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_QueueShipPatternRows
                subq.w  #1,(ShipGridTimer).l
                bne.w   Cutscene_Return
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_HoldFirstShipGrid
; Reverses horizontal velocity while restoring the first ship-grid pattern
Cutscene_RevealFirstShipGrid:                           ; was: sub_54B6
                addi.l  #$80,(TwelfthEntityXVel).w
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_RevealShipPatternStep
                bsr.w   Cutscene_QueueShipPatternRows
                tst.w   (ShipPatternStep).l
                bpl.w   Cutscene_Return
                clr.l   (TwelfthEntityXVel).w
                move.w  #$100,(ShipGridTimer).l
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_RevealFirstShipGrid
; Reconfigures the object as the second 4-by-2 ship grid
Cutscene_SetupSecondShipGrid:                           ; was: sub_54E8
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_QueueShipPatternRows
                subq.w  #1,(ShipGridTimer).l
                bne.w   Cutscene_Return
                lea     (TwelfthEntityType).w,a5
                move.w  #$CC00,TwelfthEntityFlags-TwelfthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneSecondShipGridSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$C0,$10(a5)
                move.w  #$C0,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                andi.w  #$7FFF,(TwelfthEntityFlags).w
                move.w  #$4F0,(ShipGridFirstTile).l
                move.w  #$C0,(ShipGridCenterY).l
                move.w  #$C0,(ShipGridCenterX).l
                move.w  #3,(ShipGridRowLimit).l
                move.w  #1,(ShipGridColumnLimit).l
                move.l  #$5E000002,(ShipPatternVDPCommand).l
                move.w  #$F,(ShipPatternWriteOnly).l
                move.w  #3,(ShipPatternFrameMask).l
                clr.w   (ShipPatternStep).l
                jsr     Cutscene_FillShipPattern(pc)    ; (pc)
                nop
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_SetupSecondShipGrid
; Changes vertical velocity while erasing the second ship-grid pattern
Cutscene_EraseSecondShipGrid:                           ; was: sub_5586
                ori.w   #$8000,(TwelfthEntityFlags).w
                addi.l  #$40,(TwelfthEntityYVel).w      ; '@'
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_EraseShipPatternStep
                bsr.w   Cutscene_QueueShipPatternRows
                cmpi.w  #$40,(ShipPatternStep).l        ; '@'
                bne.w   Cutscene_Return
                move.w  #$80,(ShipGridTimer).l
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_EraseSecondShipGrid
; Keeps the second ship grid visible until its hold timer expires
Cutscene_HoldSecondShipGrid:                            ; was: sub_55BC
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_QueueShipPatternRows
                subq.w  #1,(ShipGridTimer).l
                bne.w   Cutscene_Return
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_HoldSecondShipGrid
; Reverses vertical velocity while restoring the second ship-grid pattern
Cutscene_RevealSecondShipGrid:                          ; was: sub_55D6
                subi.l  #$40,(TwelfthEntityYVel).w      ; '@'
                bsr.w   Cutscene_RenderShipSpriteGrid
                bsr.w   Cutscene_RevealShipPatternStep
                bsr.w   Cutscene_QueueShipPatternRows
                tst.w   (ShipPatternStep).l
                bpl.w   Cutscene_Return
                clr.w   (TwelfthEntityFlags).w
                addq.w  #2,(ShipGridState).l
                rts
; End of function Cutscene_RevealSecondShipGrid
Cutscene_ShipGridSequenceComplete:                      ; was: nullsub_16
                rts
; End of function Cutscene_ShipGridSequenceComplete

; Dispatches the two-row star-object sequence
Cutscene_DispatchStarRows:
                move.w  (StarRowState).l,d0             ; was: sub_5602
                lea     Cutscene_StarRowStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Cutscene_DispatchStarRows
; ---------------------------------------------------------------------------
Cutscene_StarRowStates: dc.w    Cutscene_StartStarRowDelay-*  ; was: off_5610
                dc.w    Cutscene_SetupStarRows-*
                dc.w    Cutscene_ExpandStarRows-*
                dc.w    Cutscene_HoldExpandedStarRows-*
                dc.w    Cutscene_CollapseStarRows-*
                dc.w    Cutscene_StarRowSequenceComplete-*

; Starts the long delay before the star objects are created
Cutscene_StartStarRowDelay:                             ; was: sub_561C
                move.w  #$2480,(StarRowTimer).l
                addq.w  #2,(StarRowState).l
                rts
; End of function Cutscene_StartStarRowDelay
; Creates ten objects arranged as two five-object rows
Cutscene_SetupStarRows:                                 ; was: sub_562C
                subq.w  #1,(StarRowTimer).l
                bne.w   Cutscene_Return
                lea     (Entity_ObjectPool).w,a5
                move.w  #$CC00,PrimaryEntityFlags-Entity_ObjectPool(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$9C,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (SecondaryEntityType).w,a5
                move.w  #$CC00,SecondaryEntityFlags-SecondaryEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$9C,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (TertiaryEntityType).w,a5
                move.w  #$CC00,TertiaryEntityFlags-TertiaryEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$9C,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (QuaternaryEntityType).w,a5
                move.w  #$CC00,QuaternaryEntityFlags-QuaternaryEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$9C,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (FifthEntityType).w,a5
                move.w  #$CC00,FifthEntityFlags-FifthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$C4,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (SixthEntityType).w,a5
                move.w  #$CC00,SixthEntityFlags-SixthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$C4,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (SeventhEntityType).w,a5
                move.w  #$CC00,SeventhEntityFlags-SeventhEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$C4,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (EighthEntityType).w,a5
                move.w  #$CC00,EighthEntityFlags-EighthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$20,$10(a5)                    ; ' '
                move.w  #$C4,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (NinthEntityType).w,a5
                move.w  #$CC00,NinthEntityFlags-NinthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$ED00,$E(a5)
                move.w  #$110,$10(a5)
                move.w  #$B0,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (TenthEntityType).w,a5
                move.w  #$CC00,TenthEntityFlags-TenthEntityType(a5)
                move.w  #$10,(a5)
                move.l  #CutsceneStarRowSpriteMappings,8(a5)
                move.w  #$E500,$E(a5)
                move.w  #$130,$10(a5)
                move.w  #$B0,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.w   (StarRowSeparation).l
                addq.w  #2,(StarRowState).l
                rts
; End of function Cutscene_SetupStarRows
; Separates the two star rows for twenty updates
Cutscene_ExpandStarRows:                                ; was: sub_5824
                addq.w  #1,(StarRowSeparation).l
                bsr.w   Cutscene_UpdateStarRowPositions
                cmpi.w  #$14,(StarRowSeparation).l
                bne.w   Cutscene_Return
                move.w  #$40,(StarRowTimer).l           ; '@'
                addq.w  #2,(StarRowState).l
                rts
; End of function Cutscene_ExpandStarRows
; Holds the expanded star rows for $40 frames
Cutscene_HoldExpandedStarRows:                          ; was: sub_584A
                subq.w  #1,(StarRowTimer).l
                bne.w   Cutscene_Return
                addq.w  #2,(StarRowState).l
                rts
; End of function Cutscene_HoldExpandedStarRows
; Collapses both star rows, then clears all ten object slots
Cutscene_CollapseStarRows:                              ; was: sub_585C
                subq.w  #1,(StarRowSeparation).l
                bsr.w   Cutscene_UpdateStarRowPositions
                tst.w   (StarRowSeparation).l
                bpl.w   Cutscene_Return
                lea     (PrimaryEntityFlags).w,a0
                move.w  #9,d0
Cutscene_ClearNextStarObject:                           ; was: loc_5878
                clr.w   (a0)
                adda.w  #$60,a0                         ; '`'
                dbf     d0,Cutscene_ClearNextStarObject
                addq.w  #2,(StarRowState).l
                rts
; End of function Cutscene_CollapseStarRows
Cutscene_StarRowSequenceComplete:                       ; was: nullsub_17
                rts
; End of function Cutscene_StarRowSequenceComplete
