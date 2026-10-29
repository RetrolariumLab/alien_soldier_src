Physics_CheckLowerTerrain:                              ; was: sub_146FC
                                        ; Physics_FacingTerrainCheckWrapper+16   j
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #$18,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrain_CheckRightInner
                bsr.w   Physics_HandleLowerLeftInnerTerrain
                bra.s   Physics_CheckLowerTerrain_CheckCenter
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrain_CheckRightInner:              ; was: loc_1471E
                moveq   #8,d0
                moveq   #$18,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrain_CheckCenter
                bsr.w   Physics_HandleLowerRightInnerTerrain
Physics_CheckLowerTerrain_CheckCenter:                  ; was: loc_1472E
                                        ; Physics_CheckLowerTerrain+2C   j
                moveq   #0,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrain_CheckLeftOuter
                bra.w   Physics_HandleLowerCenterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrain_CheckLeftOuter:               ; was: loc_1473E
                moveq   #$FFFFFFF8,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrain_CheckRightOuter
                bra.w   Physics_HandleLowerLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrain_CheckRightOuter:              ; was: loc_1474E
                moveq   #8,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrain_Return
                bra.w   Physics_HandleLowerRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrain_Return:                       ; was: locret_1475E
                rts
; End of function Physics_CheckLowerTerrain
; Probes lower terrain; only the centre and outer probes require descent
Physics_CheckLowerTerrainWhenDescending:                ; was: sub_14760
                                        ; Enemy_MainStateMachine+13E   p
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #$18,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrainWhenDescending_CheckRightInner
                bsr.w   Physics_HandleLowerLeftInnerTerrain
                bra.s   Physics_CheckLowerTerrainWhenDescending_CheckCenter
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrainWhenDescending_CheckRightInner:  ; was: loc_14782
                moveq   #8,d0
                moveq   #$18,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrainWhenDescending_CheckCenter
                bsr.w   Physics_HandleLowerRightInnerTerrain
Physics_CheckLowerTerrainWhenDescending_CheckCenter:    ; was: loc_14792
                                        ; Physics_CheckLowerTerrainWhenDescending+2C   j
                moveq   #0,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrainWhenDescending_CheckLeftOuter
                tst.w   $1C(a5)
                bmi.s   Physics_CheckLowerTerrainWhenDescending_Return
                bra.w   Physics_HandleLowerCenterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrainWhenDescending_CheckLeftOuter:  ; was: loc_147A8
                moveq   #$FFFFFFF8,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrainWhenDescending_CheckRightOuter
                tst.w   $1C(a5)
                bmi.s   Physics_CheckLowerTerrainWhenDescending_Return
                bra.w   Physics_HandleLowerLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrainWhenDescending_CheckRightOuter:  ; was: loc_147BE
                moveq   #8,d0
                moveq   #$20,d1                         ; ' '
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckLowerTerrainWhenDescending_Return
                tst.w   $1C(a5)
                bmi.s   Physics_CheckLowerTerrainWhenDescending_Return
                bra.w   Physics_HandleLowerRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckLowerTerrainWhenDescending_Return:         ; was: locret_147D4
                                        ; Physics_CheckLowerTerrainWhenDescending+58   j
                rts
; End of function Physics_CheckLowerTerrainWhenDescending
; Probes five points along the entity's upper terrain boundary
Physics_CheckUpperTerrain:                              ; was: sub_147D6
                                        ; Physics_FacingTerrainCheckWrapper+1A   j
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #$FFFFFFE8,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrain_CheckRightInner
                bsr.w   Physics_HandleUpperLeftInnerTerrain
                bra.s   Physics_CheckUpperTerrain_CheckCenter
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrain_CheckRightInner:              ; was: loc_147F8
                moveq   #8,d0
                moveq   #$FFFFFFE8,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrain_CheckCenter
                bsr.w   Physics_HandleUpperRightInnerTerrain
Physics_CheckUpperTerrain_CheckCenter:                  ; was: loc_14808
                                        ; Physics_CheckUpperTerrain+2C   j
                moveq   #0,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrain_CheckLeftOuter
                bra.w   Physics_HandleUpperCenterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrain_CheckLeftOuter:               ; was: loc_14818
                moveq   #$FFFFFFF8,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrain_CheckRightOuter
                bra.w   Physics_HandleUpperLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrain_CheckRightOuter:              ; was: loc_14828
                moveq   #8,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrain_Return
                bra.w   Physics_HandleUpperRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrain_Return:                       ; was: locret_14838
                rts
; End of function Physics_CheckUpperTerrain
; Probes upper terrain; only the centre and outer probes require ascent
Physics_CheckUpperTerrainWhenRising:                    ; was: sub_1483A
                                        ; sub_2C71E:Enemy_MainStateMachine_CheckRisingTerrain   j
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #$FFFFFFE8,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrainWhenRising_CheckRightInner
                bsr.w   Physics_HandleUpperLeftInnerTerrain
                bra.s   Physics_CheckUpperTerrainWhenRising_CheckCenter
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrainWhenRising_CheckRightInner:    ; was: loc_1485C
                moveq   #8,d0
                moveq   #$FFFFFFE8,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrainWhenRising_CheckCenter
                bsr.w   Physics_HandleUpperRightInnerTerrain
Physics_CheckUpperTerrainWhenRising_CheckCenter:        ; was: loc_1486C
                                        ; Physics_CheckUpperTerrainWhenRising+2C   j
                moveq   #0,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrainWhenRising_CheckLeftOuter
                tst.w   $1C(a5)
                bpl.s   Physics_CheckUpperTerrainWhenRising_Return
                bra.w   Physics_HandleUpperCenterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrainWhenRising_CheckLeftOuter:     ; was: loc_14882
                moveq   #$FFFFFFF8,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrainWhenRising_CheckRightOuter
                tst.w   $1C(a5)
                bpl.s   Physics_CheckUpperTerrainWhenRising_Return
                bra.w   Physics_HandleUpperLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrainWhenRising_CheckRightOuter:    ; was: loc_14898
                moveq   #8,d0
                moveq   #$FFFFFFE0,d1
                bsr.w   Physics_GetTerrainTileData
                move.w  d2,d2
                beq.s   Physics_CheckUpperTerrainWhenRising_Return
                tst.w   $1C(a5)
                bpl.s   Physics_CheckUpperTerrainWhenRising_Return
                bra.w   Physics_HandleUpperRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_CheckUpperTerrainWhenRising_Return:             ; was: locret_148AE
                                        ; Physics_CheckUpperTerrainWhenRising+58   j
                rts
; End of function Physics_CheckUpperTerrainWhenRising
; Resolves the lower-center terrain probe
Physics_HandleLowerCenterTerrain:                       ; was: sub_148B0
                                        ; Physics_CheckLowerTerrainWhenDescending+44   j
                bset    #0,6(a5)
                cmpi.w  #$80,d2
                bpl.s   Physics_HandleLowerCenterTerrain_Dispatch
                bset    #2,6(a5)
; Dispatches the lower-center response selected by terrain angle
Physics_HandleLowerCenterTerrain_Dispatch:              ; was: loc_148C2
                andi.w  #$7E,d2                         ; '~'
                cmpi.w  #$40,d2                         ; '@'
                bpl.w   Physics_SnapToLowerSurface
                movea.w Physics_LowerCenterResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleLowerLeftInnerTerrain,a4
                jmp     (a4)
; End of function Physics_HandleLowerCenterTerrain
; ---------------------------------------------------------------------------
Physics_LowerCenterResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain  ; was: off_148DA
                dc.w    Physics_SnapToLowerSurface-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_SnapToLowerSurface-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareFloorOffset8-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_CalculateFloorOffset4-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareEvenOffset4-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareEvenOffset0-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset8-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset6-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset4-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset2-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset5-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset3-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset1-Physics_HandleLowerLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffsetNegative1-Physics_HandleLowerLeftInnerTerrain

; Resolves the lower-left inner terrain probe
Physics_HandleLowerLeftInnerTerrain:                    ; was: sub_1490A
                                        ; Physics_CheckLowerTerrainWhenDescending+1C   p
                cmpi.w  #$10,d2
                bmi.w   Physics_TerrainEmptyHandler
                cmpi.w  #$C0,d2
                bpl.w   Physics_ResolveLeftWallCollision
                move.w  d2,d3
                andi.w  #$7E,d2                         ; '~'
                cmpi.w  #$40,d2                         ; '@'
                bpl.w   Physics_TerrainEmptyHandler
                cmpi.w  #$10,d2
                bmi.s   Physics_HandleLowerLeftInnerTerrain_Dispatch
                bset    #0,6(a5)
                cmpi.w  #$80,d3
                bpl.s   Physics_HandleLowerLeftInnerTerrain_Dispatch
                bset    #2,6(a5)
; Dispatches the lower-left inner response selected by terrain angle
Physics_HandleLowerLeftInnerTerrain_Dispatch:           ; was: loc_14940
                                        ; Physics_HandleLowerLeftInnerTerrain+2E   j
                movea.w Physics_LowerLeftInnerResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleLowerRightInnerTerrain,a4
                jmp     (a4)
; End of function Physics_HandleLowerLeftInnerTerrain
; ---------------------------------------------------------------------------
Physics_LowerLeftInnerResponseTable:    dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain  ; was: off_1494C
                dc.w    Physics_ResolveLeftWallCollision-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ResolveLeftWallCollision-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_SnapFloorMinus12-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_CalcFloorMinus12-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyEvenOffset4Sub4-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyEvenOffset0Sub4-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset8Sub10-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset6Sub10-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset4Sub10-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset2Sub10-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset5Sub6-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset3Sub6-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffset1Sub6-Physics_HandleLowerRightInnerTerrain
                dc.w    Physics_ApplyOffsetNegative1Sub6-Physics_HandleLowerRightInnerTerrain

; Resolves the lower-right inner terrain probe
Physics_HandleLowerRightInnerTerrain:                   ; was: sub_1497C
                                        ; Physics_CheckLowerTerrainWhenDescending+2E   p
                cmpi.w  #$10,d2
                bmi.w   Physics_TerrainEmptyHandler
                cmpi.w  #$C0,d2
                bpl.w   Physics_ResolveRightWallCollision
                move.w  d2,d3
                andi.w  #$7E,d2                         ; '~'
                cmpi.w  #$40,d2                         ; '@'
                bpl.w   Physics_TerrainEmptyHandler
                cmpi.w  #$10,d2
                bmi.s   Physics_HandleLowerRightInnerTerrain_Dispatch
                bset    #0,6(a5)
                cmpi.w  #$80,d3
                bpl.s   Physics_HandleLowerRightInnerTerrain_Dispatch
                bset    #2,6(a5)
; Dispatches the lower-right inner response selected by terrain angle
Physics_HandleLowerRightInnerTerrain_Dispatch:          ; was: loc_149B2
                                        ; Physics_HandleLowerRightInnerTerrain+2E   j
                movea.w Physics_LowerRightInnerResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleLowerLeftOuterTerrain,a4
                jmp     (a4)
; End of function Physics_HandleLowerRightInnerTerrain
; ---------------------------------------------------------------------------
Physics_LowerRightInnerResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain  ; was: off_149BE
                dc.w    Physics_ResolveRightWallCollision-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ResolveRightWallCollision-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_SnapFloorMinus4-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_CalcFloorOffsetSubtract4-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyEvenOffset4Sub12-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyEvenOffset0Sub12-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset8Sub6-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset6Sub6-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset4Sub6-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset2Sub6-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset5Sub10-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset3Sub10-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffset1Sub10-Physics_HandleLowerLeftOuterTerrain
                dc.w    Physics_ApplyOffsetNegative1Sub10-Physics_HandleLowerLeftOuterTerrain

; Resolves the lower-left outer terrain probe
Physics_HandleLowerLeftOuterTerrain:                    ; was: sub_149EE
                                        ; Physics_CheckLowerTerrainWhenDescending+5A   j
                bset    #0,6(a5)
                cmpi.w  #$80,d2
                bpl.s   Physics_HandleLowerLeftOuterTerrain_Dispatch
                bset    #2,6(a5)
; Dispatches the lower-left outer response selected by terrain angle
Physics_HandleLowerLeftOuterTerrain_Dispatch:           ; was: loc_14A00
                andi.w  #$7E,d2                         ; '~'
                cmpi.w  #$40,d2                         ; '@'
                bpl.w   Physics_SnapToLowerSurface
                movea.w Physics_LowerLeftOuterResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleLowerRightOuterTerrain,a4
                jmp     (a4)
; End of function Physics_HandleLowerLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_LowerLeftOuterResponseTable:    dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain  ; was: off_14A18
                dc.w    Physics_SnapToLowerSurface-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_SnapToLowerSurface-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_SnapFloorMinus4-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_CalcFloorOffsetSubtract4-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyEvenOffset4Add4-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyEvenOffset0Add4-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset8Sub2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset6Sub2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset4Sub2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset2Sub2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset5Add2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset3Add2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffset1Add2-Physics_HandleLowerRightOuterTerrain
                dc.w    Physics_ApplyOffsetNegative1Add2-Physics_HandleLowerRightOuterTerrain

; Resolves the lower-right outer terrain probe
Physics_HandleLowerRightOuterTerrain:                   ; was: sub_14A48
                                        ; Physics_CheckLowerTerrainWhenDescending+70   j
                bset    #0,6(a5)
                cmpi.w  #$80,d2
                bpl.s   Physics_HandleLowerRightOuterTerrain_Dispatch
                bset    #2,6(a5)
; Dispatches the lower-right outer response selected by terrain angle
Physics_HandleLowerRightOuterTerrain_Dispatch:          ; was: loc_14A5A
                andi.w  #$7E,d2                         ; '~'
                cmpi.w  #$40,d2                         ; '@'
                bpl.w   Physics_SnapToLowerSurface
                movea.w Physics_LowerRightOuterResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleUpperCenterTerrain,a4
                jmp     (a4)
; End of function Physics_HandleLowerRightOuterTerrain
; ---------------------------------------------------------------------------
Physics_LowerRightOuterResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain  ; was: off_14A72
                dc.w    Physics_SnapToLowerSurface-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_SnapToLowerSurface-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_SnapAndAdd4-Physics_HandleUpperCenterTerrain
                dc.w    Physics_CalcFloorOffsetAdd4-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyEvenOffset4Sub4-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyEvenOffset0Sub4-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset8Add2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset6Add2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset4Add2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset2Add2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset5Sub2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset3Sub2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffset1Sub2-Physics_HandleUpperCenterTerrain
                dc.w    Physics_ApplyOffsetNegative1Sub2-Physics_HandleUpperCenterTerrain

; Resolves the upper-center terrain probe
Physics_HandleUpperCenterTerrain:                       ; was: sub_14AA2
                                        ; Physics_CheckUpperTerrainWhenRising+44   j
                cmpi.w  #$80,d2
                bmi.w   Physics_SetSolidTerrainFlag
                bset    #1,6(a5)
                andi.w  #$7E,d2                         ; '~'
                subi.w  #$40,d2                         ; '@'
                bmi.w   Physics_SnapToUpperSurface
                movea.w Physics_UpperCenterResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleUpperLeftInnerTerrain,a4
                jmp     (a4)
; End of function Physics_HandleUpperCenterTerrain
; ---------------------------------------------------------------------------
Physics_UpperCenterResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain  ; was: off_14AC8
                dc.w    Physics_SnapToUpperSurface-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_SnapToUpperSurface-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareEvenOffset0-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareEvenOffset4-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_CalculateFloorOffset4-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareFloorOffset8-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffsetNegative1-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset1-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset3-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareQuarterAddOffset5-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset2-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset4-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset6-Physics_HandleUpperLeftInnerTerrain
                dc.w    Physics_PrepareVerticalOffset8-Physics_HandleUpperLeftInnerTerrain

; Resolves the upper-left inner terrain probe
Physics_HandleUpperLeftInnerTerrain:                    ; was: sub_14AF8
                                        ; Physics_CheckUpperTerrainWhenRising+1C   p
                cmpi.w  #$80,d2
                bmi.s   Physics_HandleUpperLeftInnerTerrain_NormalizeAngle
                cmpi.w  #$C0,d2
                bmi.w   Physics_ResolveLeftWallCollision
Physics_HandleUpperLeftInnerTerrain_NormalizeAngle:     ; was: loc_14B06
                andi.w  #$7E,d2                         ; '~'
                subi.w  #$40,d2                         ; '@'
                bmi.w   Physics_TerrainEmptyHandler
                cmpi.w  #$10,d2
                bmi.s   Physics_HandleUpperLeftInnerTerrain_Dispatch
                bset    #1,6(a5)
Physics_HandleUpperLeftInnerTerrain_Dispatch:           ; was: loc_14B1E
                movea.w Physics_UpperLeftInnerResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleUpperRightInnerTerrain,a4
                jmp     (a4)
; End of function Physics_HandleUpperLeftInnerTerrain
; ---------------------------------------------------------------------------
Physics_UpperLeftInnerResponseTable:    dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain  ; was: off_14B2A
                dc.w    Physics_ResolveLeftWallCollision-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_ResolveLeftWallCollision-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_ApplyEvenOffset0Add12-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_ApplyEvenOffset4Add12-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_CalcFloorOffsetAdd4-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_SnapAndAdd4-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightInnerTerrain

; Resolves the upper-right inner terrain probe
Physics_HandleUpperRightInnerTerrain:                   ; was: sub_14B5A
                                        ; Physics_CheckUpperTerrainWhenRising+2E   p
                cmpi.w  #$80,d2
                bmi.s   Physics_HandleUpperRightInnerTerrain_NormalizeAngle
                cmpi.w  #$C0,d2
                bmi.w   Physics_ResolveRightWallCollision
Physics_HandleUpperRightInnerTerrain_NormalizeAngle:    ; was: loc_14B68
                andi.w  #$7E,d2                         ; '~'
                subi.w  #$40,d2                         ; '@'
                bmi.w   Physics_TerrainEmptyHandler
                cmpi.w  #$10,d2
                bmi.s   Physics_HandleUpperRightInnerTerrain_Dispatch
                bset    #1,6(a5)
Physics_HandleUpperRightInnerTerrain_Dispatch:          ; was: loc_14B80
                movea.w Physics_UpperRightInnerResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleUpperLeftOuterTerrain,a4
                jmp     (a4)
; End of function Physics_HandleUpperRightInnerTerrain
; ---------------------------------------------------------------------------
Physics_UpperRightInnerResponseTable:   dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain  ; was: off_14B8C
                dc.w    Physics_ResolveRightWallCollision-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_ResolveRightWallCollision-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_ApplyEvenOffset0Add4-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_ApplyEvenOffset4Add4-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_CalcFloorPlus12-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_SnapFloorPlus12-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperLeftOuterTerrain

; Resolves the upper-left outer terrain probe
Physics_HandleUpperLeftOuterTerrain:                    ; was: sub_14BBC
                                        ; Physics_CheckUpperTerrainWhenRising+5A   j
                cmpi.w  #$80,d2
                bmi.w   Physics_SetSolidTerrainFlag
                bset    #1,6(a5)
                andi.w  #$7E,d2                         ; '~'
                subi.w  #$40,d2                         ; '@'
                bmi.w   Physics_SnapToUpperSurface
                movea.w Physics_UpperLeftOuterResponseTable(pc,d2.w),a4
                adda.l  #Physics_HandleUpperRightOuterTerrain,a4
                jmp     (a4)
; End of function Physics_HandleUpperLeftOuterTerrain
; ---------------------------------------------------------------------------
Physics_UpperLeftOuterResponseTable:    dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain  ; was: off_14BE2
                dc.w    Physics_SnapToUpperSurface-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_SnapToUpperSurface-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_ApplyEvenOffset0Add4-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_ApplyEvenOffset4Add4-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_CalcFloorOffsetSubtract4-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_SnapFloorMinus4-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
                dc.w    Physics_TerrainEmptyHandler-Physics_HandleUpperRightOuterTerrain
