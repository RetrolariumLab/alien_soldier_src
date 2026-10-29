; Jampan orbit-group geometry and held-input parameter adjustment

; Applies the reverse angular-velocity table, then returns to the wait state
Boss_JampanRotateOrbitGroupBackwardState:               ; DATA XREF: ROM:0004A54C   o  ; was: sub_4A5F0
                move.w  #$C,d7
                movea.w #(TenthEntityType-M68K_RAM),a0
                clr.w   d6
Boss_JampanRotateOrbitGroupBackwardLoop:                ; CODE XREF: Boss_JampanRotateOrbitGroupBackwardState+28   j  ; was: loc_4A5FA
                move.l  Boss_JampanBackwardAngularVelocityTable(pc,d6.w),d0
                add.l   d0,$54(a0)
                add.l   d0,$54(a0)
                move.w  $54(a0),$4C(a0)
                andi.w  #$1FF,$4C(a0)
                addq.w  #4,d6
                lea     $60(a0),a0
                dbf     d7,Boss_JampanRotateOrbitGroupBackwardLoop
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanRotateOrbitGroupBackwardReturn
                move.w  #2,4(a5)
Boss_JampanRotateOrbitGroupBackwardReturn:              ; CODE XREF: Boss_JampanRotateOrbitGroupBackwardState+30   j  ; was: locret_4A628
                rts
; End of function Boss_JampanRotateOrbitGroupBackwardState
; ---------------------------------------------------------------------------
Boss_JampanBackwardAngularVelocityTable:    dc.l    $800, $1000, $2000, $2000, $2000, $1000, $800  ; was: dword_4A62A
                                        ; DATA XREF: Boss_JampanRotateOrbitGroupBackwardState:Boss_JampanRotateOrbitGroupBackwardLoop   r
                dc.l    $FFFFC000, $FFFF8000, $FFFF4000, $FFFF4000, $FFFF8000, $FFFFC000

; Adjusts shared orbit parameters from held controller-button combinations
; This remains active in the post-defeat movement states; an original debug or
; gameplay purpose is not claimed without runtime evidence
;
; Controller Input Mapping (ControllerHeldState = Controller 1 input):
; UP + A      : Decrease SharedScratchLong0 by 2
; UP + B      : Decrease SharedScratchLong1 by 2
; UP + C      : Decrease SharedScratchLong2 by 2
; DOWN + A    : Increase SharedScratchLong0 by 2
; DOWN + B    : Increase SharedScratchLong1 by 2
; DOWN + C    : Increase SharedScratchLong2 by 2
; LEFT + START : Increase SharedScratchLong9 by 2
; RIGHT + START: Decrease SharedScratchLong9 by 2
;
; Button bit mapping:
; Bit 0 = LEFT, Bit 1 = RIGHT, Bit 2 = UP, Bit 3 = DOWN
; Bit 4 = B, Bit 5 = C, Bit 6 = A, Bit 7 = START
Boss_JampanAdjustOrbitParametersFromInput:              ; CODE XREF: Boss_JampanInitializePostDefeatMovementState+10   p  ; was: sub_4A65E
                                        ; Boss_JampanUpdatePostDefeatMovementState+4   p
                btst    #2,(ControllerHeldState).w      ; Test UP button on controller 1
                beq.s   Boss_JampanCheckDownOrbitAdjustments
                btst    #6,(ControllerHeldState).w
                beq.s   Boss_JampanCheckUpBOrbitAdjustment
                subq.w  #2,(SharedScratchLong0).w
Boss_JampanCheckUpBOrbitAdjustment:                     ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+E   j  ; was: loc_4A672
                btst    #4,(ControllerHeldState).w
                beq.s   Boss_JampanCheckUpCOrbitAdjustment
                subq.w  #2,(SharedScratchLong1).w
Boss_JampanCheckUpCOrbitAdjustment:                     ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+1A   j  ; was: loc_4A67E
                btst    #5,(ControllerHeldState).w
                beq.s   Boss_JampanCheckDownOrbitAdjustments
                subq.w  #2,(SharedScratchLong2).w
Boss_JampanCheckDownOrbitAdjustments:                   ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+6   j  ; was: loc_4A68A
                                        ; Boss_JampanAdjustOrbitParametersFromInput+26   j
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_JampanCheckLeftStartOffsetAdjustment
                btst    #6,(ControllerHeldState).w
                beq.s   Boss_JampanCheckDownBOrbitAdjustment
                addq.w  #2,(SharedScratchLong0).w
Boss_JampanCheckDownBOrbitAdjustment:                   ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+3A   j  ; was: loc_4A69E
                btst    #4,(ControllerHeldState).w
                beq.s   Boss_JampanCheckDownCOrbitAdjustment
                addq.w  #2,(SharedScratchLong1).w
Boss_JampanCheckDownCOrbitAdjustment:                   ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+46   j  ; was: loc_4A6AA
                btst    #5,(ControllerHeldState).w
                beq.s   Boss_JampanCheckLeftStartOffsetAdjustment
                addq.w  #2,(SharedScratchLong2).w
Boss_JampanCheckLeftStartOffsetAdjustment:              ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+32   j  ; was: loc_4A6B6
                                        ; Boss_JampanAdjustOrbitParametersFromInput+52   j
                btst    #0,(ControllerHeldState).w
                beq.s   Boss_JampanCheckRightStartOffsetAdjustment
                btst    #7,(ControllerHeldState).w
                beq.s   Boss_JampanCheckRightStartOffsetAdjustment
                addq.w  #2,(SharedScratchLong9).w
Boss_JampanCheckRightStartOffsetAdjustment:             ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+5E   j  ; was: loc_4A6CA
                                        ; Boss_JampanAdjustOrbitParametersFromInput+66   j
                btst    #1,(ControllerHeldState).w
                beq.s   Boss_JampanAdjustOrbitParametersFromInputReturn
                btst    #7,(ControllerHeldState).w
                beq.s   Boss_JampanAdjustOrbitParametersFromInputReturn
                subq.w  #2,(SharedScratchLong9).w
Boss_JampanAdjustOrbitParametersFromInputReturn:        ; CODE XREF: Boss_JampanAdjustOrbitParametersFromInput+72   j  ; was: locret_4A6DE
                                        ; Boss_JampanAdjustOrbitParametersFromInput+7A   j
                rts
; End of function Boss_JampanAdjustOrbitParametersFromInput
; Publishes controller-derived coordinates for the stage systems
Boss_JampanPublishStageCoordinates:                     ; CODE XREF: Boss_JampanMain+4   p  ; was: sub_4A6E0
                move.w  #$A4,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$4C,d0                         ; 'L'
                move.w  d0,(SecondaryCameraYPos).w
                rts
; End of function Boss_JampanPublishStageCoordinates
; Advances shared angles and projects all sixteen orbiting parts
Boss_JampanUpdateOrbitingPartGeometry:                  ; CODE XREF: Boss_JampanInitializeEncounterState+1E2   p  ; was: sub_4A6FA
                                        ; sub_4953E   p
                tst.l   (SharedScratchLong3).w
                beq.s   Boss_JampanUpdateSecondaryOrbitAngle
                move.l  (SharedScratchLong3).w,d0
                add.l   d0,(SharedScratchLong0).w
Boss_JampanUpdateSecondaryOrbitAngle:                   ; CODE XREF: Boss_JampanUpdateOrbitingPartGeometry+4   j  ; was: loc_4A708
                tst.l   (SharedScratchLong4).w
                beq.s   Boss_JampanUpdateTertiaryOrbitAngle
                move.l  (SharedScratchLong4).w,d0
                add.l   d0,(SharedScratchLong1).w
Boss_JampanUpdateTertiaryOrbitAngle:                    ; CODE XREF: Boss_JampanUpdateOrbitingPartGeometry+12   j  ; was: loc_4A716
                tst.l   (SharedScratchLong5).w
                beq.s   Boss_JampanNormalizeOrbitAngles
                move.l  (SharedScratchLong5).w,d0
                add.l   d0,(SharedScratchLong2).w
Boss_JampanNormalizeOrbitAngles:                        ; CODE XREF: Boss_JampanUpdateOrbitingPartGeometry+20   j  ; was: loc_4A724
                andi.w  #$1FF,(SharedScratchLong0).w
                andi.w  #$1FF,(SharedScratchLong1).w
                andi.w  #$1FF,(SharedScratchLong2).w
                movea.w a5,a1
                lea     (SeventhEntityType).w,a0
                move.w  #$F,d0
Boss_JampanProjectNextOrbitingPart:                     ; CODE XREF: Boss_JampanUpdateOrbitingPartGeometry+8A   j  ; was: loc_4A740
                lea     (Math_SineTable).l,a2
                move.w  $48(a0),d4
                add.w   (SharedScratchLong9).w,d4
                move.w  $4A(a0),d5
                move.w  $4C(a0),d6
                move.w  $4E(a0),d7
                add.w   (SharedScratchLong0).w,d5
                add.w   (SharedScratchLong9+2).w,d5
                add.w   (SharedScratchLong1).w,d6
                add.w   (SharedScratchLong10).w,d6
                add.w   (SharedScratchLong2).w,d7
                add.w   (SharedScratchLong10+2).w,d6
                andi.w  #$1FE,d5
                andi.w  #$1FE,d6
                andi.w  #$1FE,d7
                bsr.s   Boss_JampanProjectPartFromAngles
                lea     $60(a0),a0
                dbf     d0,Boss_JampanProjectNextOrbitingPart
                rts
; End of function Boss_JampanUpdateOrbitingPartGeometry
; Projects one linked part from three angles and a radius
Boss_JampanProjectPartFromAngles:                       ; CODE XREF: Boss_JampanUpdateShieldFormationGeometry+3C   p  ; was: sub_4A78A
                                        ; sub_4A160:Boss_JampanProjectNextShieldObject   p
                move.w  -$80(a2,d5.w),d1
                muls.w  d4,d1
                swap    d1
                add.w   d1,d1
                add.w   d1,d1
                move.w  (a2,d6.w),d2
                muls.w  d2,d1
                swap    d1
                cmpi.w  #$3F,d1                         ; '?'
                blt.s   Boss_JampanClampProjectedDepthMinimum
                move.w  #$3F,d1                         ; '?'
                bra.s   Boss_JampanApplyProjectedPartDepth
; ---------------------------------------------------------------------------
Boss_JampanClampProjectedDepthMinimum:                  ; CODE XREF: Boss_JampanProjectPartFromAngles+18   j  ; was: loc_4A7AA
                cmpi.w  #$FFC1,d1
                bgt.s   Boss_JampanApplyProjectedPartDepth
                move.w  #$FFC1,d1
Boss_JampanApplyProjectedPartDepth:                     ; CODE XREF: Boss_JampanProjectPartFromAngles+1E   j  ; was: loc_4A7B4
                                        ; Boss_JampanProjectPartFromAngles+24   j
                clr.w   d2
                move.b  $20(a1),d2
                add.w   d2,d1
                move.b  d1,$20(a0)
                cmp.b   $20(a1),d1
                bhi.s   Boss_JampanClearProjectedPartPriorityFlag
                ori.w   #$8000,$E(a0)
                bra.s   Boss_JampanCalculateProjectedPartPosition
; ---------------------------------------------------------------------------
Boss_JampanClearProjectedPartPriorityFlag:              ; CODE XREF: Boss_JampanProjectPartFromAngles+3A   j  ; was: loc_4A7CE
                andi.w  #$7FFF,$E(a0)
Boss_JampanCalculateProjectedPartPosition:              ; CODE XREF: Boss_JampanProjectPartFromAngles+42   j  ; was: loc_4A7D4
                move.w  (a2,d5.w),d1
                move.w  (a2,d7.w),d2
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                move.l  d2,d3
                move.w  -$80(a2,d5.w),d1
                move.w  -$80(a2,d6.w),d2
                muls.w  d1,d2
                swap    d2
                add.w   d2,d2
                add.w   d2,d2
                move.w  -$80(a2,d7.w),d1
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                sub.l   d2,d3
                swap    d3
                muls.w  d4,d3
                add.l   d3,d3
                add.l   d3,d3
                add.l   $10(a1),d3
                move.l  d3,$10(a0)
                move.w  (a2,d5.w),d1
                move.w  -$80(a2,d7.w),d2
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                move.l  d2,d3
                move.w  -$80(a2,d5.w),d1
                move.w  -$80(a2,d6.w),d2
                muls.w  d1,d2
                swap    d2
                add.w   d2,d2
                add.w   d2,d2
                move.w  (a2,d7.w),d1
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                add.l   d2,d3
                swap    d3
                muls.w  d4,d3
                add.l   d3,d3
                add.l   d3,d3
                add.l   $14(a1),d3
                move.l  d3,$14(a0)
                rts
; End of function Boss_JampanProjectPartFromAngles
