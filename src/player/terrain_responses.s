Physics_HandleUpperRightOuterTerrain:                   ; was: sub_14C12
                                        ; Physics_CheckUpperTerrainWhenRising+70   j
                cmpi.w  #$80,d2
                bmi.w   Physics_SetSolidTerrainFlag
                bset    #1,6(a5)
                andi.w  #$7E,d2                         ; '~'
                subi.w  #$40,d2                         ; '@'
                bmi.w   Physics_SnapToUpperSurface
                movea.w Physics_UpperRightOuterResponseTable(pc,d2.w),a4
                adda.l  #Physics_TerrainEmptyHandler,a4
                jmp     (a4)
; End of function Physics_HandleUpperRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_UpperRightOuterResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler  ; was: off_14C38
                dc.w    Physics_SnapToUpperSurface-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_SnapToUpperSurface-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_ApplyEvenOffset0Sub4-Physics_TerrainEmptyHandler
                dc.w    Physics_ApplyEvenOffset4Sub4-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_CalcFloorOffsetAdd4-Physics_TerrainEmptyHandler
                dc.w    Physics_SnapAndAdd4-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler
                dc.w    Physics_TerrainEmptyHandler-Physics_TerrainEmptyHandler

; Empty terrain angle physics handler
Physics_TerrainEmptyHandler:                            ; was: nullsub_35
                                        ; Physics_HandleLowerLeftInnerTerrain+1A   j
                rts
; End of function Physics_TerrainEmptyHandler
; Sets solid terrain collision flag (bit 2 in collision flags)
Physics_SetSolidTerrainFlag:                            ; was: sub_14C6A
                                        ; Physics_HandleUpperLeftOuterTerrain+4   j
                bset    #2,6(a5)
                rts
; End of function Physics_SetSolidTerrainFlag
; Clears vertical velocity and snaps the entity to a lower surface
Physics_SnapToLowerSurface:                             ; was: sub_14C72
                                        ; Physics_HandleLowerLeftOuterTerrain+1A   j
                clr.l   $1C(a5)
                move.w  d1,d4
                sub.w   (PrimaryCameraYPosition).w,d4
                andi.w  #7,d4
                sub.w   d4,$14(a5)
                rts
; End of function Physics_SnapToLowerSurface
; Clears vertical velocity and snaps the entity to an upper surface
Physics_SnapToUpperSurface:                             ; was: sub_14C86
                                        ; Physics_HandleUpperLeftOuterTerrain+16   j
                clr.l   $1C(a5)
                move.w  d1,d4
                sub.w   (PrimaryCameraYPosition).w,d4
                neg.w   d4
                subq.w  #1,d4
                andi.w  #7,d4
                add.w   d4,$14(a5)
                rts
; End of function Physics_SnapToUpperSurface
; Snaps to floor and subtracts 12 pixels
Physics_SnapFloorMinus12:                               ; was: sub_14C9E
                bsr.w   Physics_PrepareFloorOffset8
                subi.w  #$C,$14(a5)
                rts
; End of function Physics_SnapFloorMinus12
; Snaps to floor and subtracts 4 pixels
Physics_SnapFloorMinus4:                                ; was: sub_14CAA
                                        ; ROM:00014A28   o
                bsr.s   Physics_PrepareFloorOffset8
                subq.w  #4,$14(a5)
                rts
; End of function Physics_SnapFloorMinus4
; Snaps to floor and adds 4 pixels
Physics_SnapAndAdd4:                                    ; was: sub_14CB2
                                        ; ROM:00014B44   o
                bsr.s   Physics_PrepareFloorOffset8
                addq.w  #4,$14(a5)
                rts
; End of function Physics_SnapAndAdd4
; Snaps to floor and adds 12 pixels
Physics_SnapFloorPlus12:                                ; was: sub_14CBA
                bsr.s   Physics_PrepareFloorOffset8
                addi.w  #$C,$14(a5)
                rts
; End of function Physics_SnapFloorPlus12
; Calculates floor offset minus 12 pixels
Physics_CalcFloorMinus12:                               ; was: sub_14CC4
                bsr.s   Physics_CalculateFloorOffset4
                subi.w  #$C,$14(a5)
                rts
; End of function Physics_CalcFloorMinus12
; Calculates floor offset and subtracts 4
Physics_CalcFloorOffsetSubtract4:                       ; was: sub_14CCE
                                        ; ROM:00014A2A   o
                bsr.s   Physics_CalculateFloorOffset4
                subq.w  #4,$14(a5)
                rts
; End of function Physics_CalcFloorOffsetSubtract4
; Applies the half-step floor alignment seeded with 4, then adds 4 to Y
Physics_CalcFloorOffsetAdd4:                            ; was: sub_14CD6
                                        ; ROM:00014B42   o
                bsr.s   Physics_CalculateFloorOffset4
                addq.w  #4,$14(a5)
                rts
; End of function Physics_CalcFloorOffsetAdd4
; Calculates floor offset plus 12 pixels
Physics_CalcFloorPlus12:                                ; was: sub_14CDE
                bsr.s   Physics_CalculateFloorOffset4
                addi.w  #$C,$14(a5)
                rts
; End of function Physics_CalcFloorPlus12
; Prepares d3=8 for floor offset
Physics_PrepareFloorOffset8:                            ; was: sub_14CE8
                                        ; sub_14CAA   p
                moveq   #8,d3
                bra.s   Physics_AlignToFloorWithOffset
; End of function Physics_PrepareFloorOffset8
; Calculates floor offset d3=4 base
Physics_CalculateFloorOffset4:                          ; was: sub_14CEC
                                        ; sub_14CCE   p
                moveq   #4,d3
; Aligns entity to floor with calculated pixel offset
Physics_AlignToFloorWithOffset:                         ; was: loc_14CEE
                bsr.w   Physics_SnapToLowerSurface
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #7,d4
                asr.w   #1,d4
                addq.w  #1,d4
                sub.w   d4,d3
                add.w   d3,$14(a5)
                rts
; End of function Physics_CalculateFloorOffset4
; Applies the even floor alignment seeded with 4, then adds 4 to Y
Physics_ApplyEvenOffset4Add4:                           ; was: sub_14D08
                                        ; ROM:00014B9E   o
                bsr.s   Physics_PrepareEvenOffset4
                addq.w  #4,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset4Add4
; Applies the even floor alignment seeded with 4, then subtracts 12 from Y
Physics_ApplyEvenOffset4Sub12:                          ; was: sub_14D10
                bsr.s   Physics_PrepareEvenOffset4
                subi.w  #$C,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset4Sub12
; Applies the even floor alignment seeded with 4, then subtracts 4 from Y
Physics_ApplyEvenOffset4Sub4:                           ; was: sub_14D1A
                                        ; ROM:00014A8A   o
                bsr.s   Physics_PrepareEvenOffset4
                subq.w  #4,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset4Sub4
; Applies the even floor alignment seeded with 4, then adds 12 to Y
Physics_ApplyEvenOffset4Add12:                          ; was: sub_14D22
                bsr.s   Physics_PrepareEvenOffset4
                addi.w  #$C,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset4Add12
; Applies the even floor alignment seeded with 0, then adds 4 to Y
Physics_ApplyEvenOffset0Add4:                           ; was: sub_14D2C
                                        ; ROM:00014B9C   o
                bsr.s   Physics_PrepareEvenOffset0
                addq.w  #4,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset0Add4
; Applies the even floor alignment seeded with 0, then subtracts 12 from Y
Physics_ApplyEvenOffset0Sub12:                          ; was: sub_14D34
                bsr.s   Physics_PrepareEvenOffset0
                subi.w  #$C,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset0Sub12
; Applies the even floor alignment seeded with 0, then subtracts 4 from Y
Physics_ApplyEvenOffset0Sub4:                           ; was: sub_14D3E
                                        ; ROM:00014A8C   o
                bsr.s   Physics_PrepareEvenOffset0
                subq.w  #4,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset0Sub4
; Applies the even floor alignment seeded with 0, then adds 12 to Y
Physics_ApplyEvenOffset0Add12:                          ; was: sub_14D46
                bsr.s   Physics_PrepareEvenOffset0
                addi.w  #$C,$14(a5)
                rts
; End of function Physics_ApplyEvenOffset0Add12
; Seeds the even floor-alignment response with 4
Physics_PrepareEvenOffset4:                             ; was: sub_14D50
                                        ; sub_14D10   p
                moveq   #4,d3
                bra.s   Physics_AlignFloorEvenOffset
; End of function Physics_PrepareEvenOffset4
; Seeds the even floor-alignment response with 0
Physics_PrepareEvenOffset0:                             ; was: sub_14D54
                                        ; sub_14D34   p
                moveq   #0,d3
Physics_AlignFloorEvenOffset:                           ; was: loc_14D56
                bsr.w   Physics_SnapToLowerSurface
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #6,d4
                asr.w   #1,d4
                add.w   d4,d3
                add.w   d3,$14(a5)
                rts
; End of function Physics_PrepareEvenOffset0
; Quarter-step alignment seeded with 8, then 10 subtracted from Y
Physics_ApplyOffset8Sub10:                              ; was: sub_14D6E
                bsr.w   Physics_PrepareVerticalOffset8
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset8Sub10
; Quarter-step alignment seeded with 8, then 6 subtracted from Y
Physics_ApplyOffset8Sub6:                               ; was: sub_14D7A
                bsr.s   Physics_PrepareVerticalOffset8
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset8Sub6
; Quarter-step alignment seeded with 8, then 2 subtracted from Y
Physics_ApplyOffset8Sub2:                               ; was: sub_14D82
                bsr.s   Physics_PrepareVerticalOffset8
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset8Sub2
; Quarter-step alignment seeded with 8, then 2 added to Y
Physics_ApplyOffset8Add2:                               ; was: sub_14D8A
                bsr.s   Physics_PrepareVerticalOffset8
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset8Add2
; Quarter-step alignment seeded with 6, then 10 subtracted from Y
Physics_ApplyOffset6Sub10:                              ; was: sub_14D92
                bsr.s   Physics_PrepareVerticalOffset6
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset6Sub10
; Quarter-step alignment seeded with 6, then 6 subtracted from Y
Physics_ApplyOffset6Sub6:                               ; was: sub_14D9C
                bsr.s   Physics_PrepareVerticalOffset6
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset6Sub6
; Quarter-step alignment seeded with 6, then 2 subtracted from Y
Physics_ApplyOffset6Sub2:                               ; was: sub_14DA4
                bsr.s   Physics_PrepareVerticalOffset6
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset6Sub2
; Quarter-step alignment seeded with 6, then 2 added to Y
Physics_ApplyOffset6Add2:                               ; was: sub_14DAC
                bsr.s   Physics_PrepareVerticalOffset6
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset6Add2
; Quarter-step alignment seeded with 4, then 10 subtracted from Y
Physics_ApplyOffset4Sub10:                              ; was: sub_14DB4
                bsr.s   Physics_PrepareVerticalOffset4
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset4Sub10
; Quarter-step alignment seeded with 4, then 6 subtracted from Y
Physics_ApplyOffset4Sub6:                               ; was: sub_14DBE
                bsr.s   Physics_PrepareVerticalOffset4
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset4Sub6
; Quarter-step alignment seeded with 4, then 2 subtracted from Y
Physics_ApplyOffset4Sub2:                               ; was: sub_14DC6
                bsr.s   Physics_PrepareVerticalOffset4
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset4Sub2
; Quarter-step alignment seeded with 4, then 2 added to Y
Physics_ApplyOffset4Add2:                               ; was: sub_14DCE
                bsr.s   Physics_PrepareVerticalOffset4
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset4Add2
; Applies the quarter-step floor alignment seeded with 2, then subtracts 10 from Y
Physics_ApplyOffset2Sub10:                              ; was: sub_14DD6
                bsr.s   Physics_PrepareVerticalOffset2
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset2Sub10
; Applies the quarter-step floor alignment seeded with 2, then subtracts 6 from Y
Physics_ApplyOffset2Sub6:                               ; was: sub_14DE0
                bsr.s   Physics_PrepareVerticalOffset2
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset2Sub6
; Applies the quarter-step floor alignment seeded with 2, then subtracts 2 from Y
Physics_ApplyOffset2Sub2:                               ; was: sub_14DE8
                bsr.s   Physics_PrepareVerticalOffset2
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset2Sub2
; Applies the quarter-step floor alignment seeded with 2, then adds 2 to Y
Physics_ApplyOffset2Add2:                               ; was: sub_14DF0
                bsr.s   Physics_PrepareVerticalOffset2
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset2Add2
; Prepares d3=8 for vertical offset
Physics_PrepareVerticalOffset8:                         ; was: sub_14DF8
                                        ; sub_14D7A   p
                moveq   #8,d3
                bra.s   Physics_AlignFloorQuarterSubtractOffset
; End of function Physics_PrepareVerticalOffset8
; Prepares d3=6 for vertical offset
Physics_PrepareVerticalOffset6:                         ; was: sub_14DFC
                                        ; sub_14D9C   p
                moveq   #6,d3
                bra.s   Physics_AlignFloorQuarterSubtractOffset
; End of function Physics_PrepareVerticalOffset6
; Seeds the quarter-step floor-alignment response with 4
Physics_PrepareVerticalOffset4:                         ; was: sub_14E00
                                        ; sub_14DBE   p
                moveq   #4,d3
                bra.s   Physics_AlignFloorQuarterSubtractOffset
; End of function Physics_PrepareVerticalOffset4
; Seeds the quarter-step floor-alignment response with 2
Physics_PrepareVerticalOffset2:                         ; was: sub_14E04
                                        ; sub_14DE0   p
                moveq   #2,d3
Physics_AlignFloorQuarterSubtractOffset:                ; was: loc_14E06
                                        ; Physics_PrepareVerticalOffset6+2   j
                bsr.w   Physics_SnapToLowerSurface
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #7,d4
                asr.w   #2,d4
                addq.w  #1,d4
                sub.w   d4,d3
                add.w   d3,$14(a5)
                rts
; End of function Physics_PrepareVerticalOffset2
; Applies the quarter-step additive alignment seeded with 5, then subtracts 6 from Y
Physics_ApplyOffset5Sub6:                               ; was: sub_14E20
                bsr.w   Physics_PrepareQuarterAddOffset5
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset5Sub6
; Applies the quarter-step additive alignment seeded with 5, then subtracts 10 from Y
Physics_ApplyOffset5Sub10:                              ; was: sub_14E2A
                bsr.s   Physics_PrepareQuarterAddOffset5
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset5Sub10
; Applies the quarter-step additive alignment seeded with 5, then adds 2 to Y
Physics_ApplyOffset5Add2:                               ; was: sub_14E34
                bsr.s   Physics_PrepareQuarterAddOffset5
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset5Add2
; Applies the quarter-step additive alignment seeded with 5, then subtracts 2 from Y
Physics_ApplyOffset5Sub2:                               ; was: sub_14E3C
                bsr.s   Physics_PrepareQuarterAddOffset5
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset5Sub2
; Applies the quarter-step additive alignment seeded with 3, then subtracts 6 from Y
Physics_ApplyOffset3Sub6:                               ; was: sub_14E44
                bsr.s   Physics_PrepareQuarterAddOffset3
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset3Sub6
; Applies the quarter-step additive alignment seeded with 3, then subtracts 10 from Y
Physics_ApplyOffset3Sub10:                              ; was: sub_14E4C
                bsr.s   Physics_PrepareQuarterAddOffset3
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset3Sub10
; Applies the quarter-step additive alignment seeded with 3, then adds 2 to Y
Physics_ApplyOffset3Add2:                               ; was: sub_14E56
                bsr.s   Physics_PrepareQuarterAddOffset3
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset3Add2
; Applies the quarter-step additive alignment seeded with 3, then subtracts 2 from Y
Physics_ApplyOffset3Sub2:                               ; was: sub_14E5E
                bsr.s   Physics_PrepareQuarterAddOffset3
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset3Sub2
; Applies the quarter-step additive alignment seeded with 1, then subtracts 6 from Y
Physics_ApplyOffset1Sub6:                               ; was: sub_14E66
                bsr.s   Physics_PrepareQuarterAddOffset1
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffset1Sub6
; Applies the quarter-step additive alignment seeded with 1, then subtracts 10 from Y
Physics_ApplyOffset1Sub10:                              ; was: sub_14E6E
                bsr.s   Physics_PrepareQuarterAddOffset1
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffset1Sub10
; Applies the quarter-step additive alignment seeded with 1, then adds 2 to Y
Physics_ApplyOffset1Add2:                               ; was: sub_14E78
                bsr.s   Physics_PrepareQuarterAddOffset1
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset1Add2
; Applies the quarter-step additive alignment seeded with 1, then subtracts 2 from Y
Physics_ApplyOffset1Sub2:                               ; was: sub_14E80
                bsr.s   Physics_PrepareQuarterAddOffset1
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffset1Sub2
; Applies the quarter-step additive alignment seeded with -1, then subtracts 6 from Y
Physics_ApplyOffsetNegative1Sub6:                       ; was: sub_14E88
                bsr.s   Physics_PrepareQuarterAddOffsetNegative1
                subq.w  #6,$14(a5)
                rts
; End of function Physics_ApplyOffsetNegative1Sub6
; Applies the quarter-step additive alignment seeded with -1, then subtracts 10 from Y
Physics_ApplyOffsetNegative1Sub10:                      ; was: sub_14E90
                bsr.s   Physics_PrepareQuarterAddOffsetNegative1
                subi.w  #$A,$14(a5)
                rts
; End of function Physics_ApplyOffsetNegative1Sub10
; Applies the quarter-step additive alignment seeded with -1, then adds 2 to Y
Physics_ApplyOffsetNegative1Add2:                       ; was: sub_14E9A
                bsr.s   Physics_PrepareQuarterAddOffsetNegative1
                addq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffsetNegative1Add2
; Applies the quarter-step additive alignment seeded with -1, then subtracts 2 from Y
Physics_ApplyOffsetNegative1Sub2:                       ; was: sub_14EA2
                bsr.s   Physics_PrepareQuarterAddOffsetNegative1
                subq.w  #2,$14(a5)
                rts
; End of function Physics_ApplyOffsetNegative1Sub2
; Seeds the quarter-step additive floor-alignment response with 5
Physics_PrepareQuarterAddOffset5:                       ; was: sub_14EAA
                                        ; sub_14E2A   p
                moveq   #5,d3
                bra.s   Physics_AlignFloorQuarterAddOffset
; End of function Physics_PrepareQuarterAddOffset5
; Seeds the quarter-step additive floor-alignment response with 3
Physics_PrepareQuarterAddOffset3:                       ; was: sub_14EAE
                                        ; sub_14E4C   p
                moveq   #3,d3
                bra.s   Physics_AlignFloorQuarterAddOffset
; End of function Physics_PrepareQuarterAddOffset3
; Seeds the quarter-step additive floor-alignment response with 1
Physics_PrepareQuarterAddOffset1:                       ; was: sub_14EB2
                                        ; sub_14E6E   p
                moveq   #1,d3
                bra.s   Physics_AlignFloorQuarterAddOffset
; End of function Physics_PrepareQuarterAddOffset1
; Seeds the quarter-step additive floor-alignment response with -1
Physics_PrepareQuarterAddOffsetNegative1:               ; was: sub_14EB6
                                        ; sub_14E90   p
                moveq   #$FFFFFFFF,d3
Physics_AlignFloorQuarterAddOffset:                     ; was: loc_14EB8
                                        ; Physics_PrepareQuarterAddOffset3+2   j
                bsr.w   Physics_SnapToLowerSurface
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #7,d4
                asr.w   #2,d4
                addq.w  #1,d4
                add.w   d4,d3
                add.w   d3,$14(a5)
                rts
; End of function Physics_PrepareQuarterAddOffsetNegative1
; Marks and resolves penetration into the entity's right wall
Physics_ResolveRightWallCollision:                      ; was: sub_14ED2
                                        ; Physics_EntityExtendedWallCheck+5A   j
                bset    #1,7(a5)
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #7,d4
                addq.w  #1,d4
                sub.w   d4,$10(a5)
                rts
; End of function Physics_ResolveRightWallCollision
; Marks and resolves penetration into the entity's left wall
Physics_ResolveLeftWallCollision:                       ; was: sub_14EEA
                                        ; Physics_EntityExtendedWallCheck+2E   p
                bset    #0,7(a5)
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                neg.w   d4
                subq.w  #1,d4
                andi.w  #7,d4
                addq.w  #1,d4
                add.w   d4,$10(a5)
                rts
; End of function Physics_ResolveLeftWallCollision
