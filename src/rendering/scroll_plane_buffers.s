; Select plane table bases and populate their horizontal and vertical scroll buffers
Scroll_PreparePlaneBuffersAndRegisterShadows:           ; was: sub_103FA
                                        ; StoryScreen_MainLoop+56   p
                move.w  #$8230,(VDPReg2Shadow).w
                move.w  #$8407,(VDPReg4Shadow).w
                tst.w   (ScrollPlaneBufferOffset).w
                beq.s   Scroll_PreparePlaneBufferValues
                move.w  #$8238,(VDPReg2Shadow).w
                move.w  #$8406,(VDPReg4Shadow).w
Scroll_PreparePlaneBufferValues:                        ; was: loc_10418
                move.b  (VDPReg11Shadow+1).w,d3
                move.b  d3,d4
                andi.w  #3,d3
                andi.w  #4,d4
                move.b  (PlaneAScrollModeFlags).w,d5
                movea.w #(HScrollBuffer-M68K_RAM),a0
                movea.w #(HScrollPlaneARow32-M68K_RAM),a1
                adda.w  (ScrollPlaneBufferOffset).w,a0
                adda.w  (ScrollPlaneBufferOffset).w,a1
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                move.w  (PlaneAShakeOffset).w,d1
                bsr.w   Scroll_WriteHorizontalPlaneBuffer
                movea.w #(VScrollBuffer-M68K_RAM),a0
                adda.w  (ScrollPlaneBufferOffset).w,a0
                move.w  (PrimaryCameraYPosition).w,d0
                neg.w   d0
                add.w   (PlaneAShakeOffset).w,d0
                bsr.w   Scroll_WriteVerticalPlaneBuffer
                move.b  (PlaneBScrollModeFlags).w,d5
                movea.w #(HScrollPlaneBRow0-M68K_RAM),a0
                movea.w #(HScrollPlaneBRow32-M68K_RAM),a1
                suba.w  (ScrollPlaneBufferOffset).w,a0
                suba.w  (ScrollPlaneBufferOffset).w,a1
                move.w  (SecondaryCameraXPos).w,d0
                neg.w   d0
                move.w  (PlaneBShakeOffset).w,d1
                bsr.w   Scroll_WriteHorizontalPlaneBuffer
                movea.w #(VScrollPlaneBColumn0-M68K_RAM),a0
                suba.w  (ScrollPlaneBufferOffset).w,a0
                move.w  (SecondaryCameraYPos).w,d0
                neg.w   d0
                add.w   (PlaneBShakeOffset).w,d0
                bra.w   Scroll_WriteVerticalPlaneBuffer
; End of function Scroll_PreparePlaneBuffersAndRegisterShadows
; Populate one plane's horizontal-scroll entries according to its mode flags
Scroll_WriteHorizontalPlaneBuffer:                      ; was: sub_10496
                                        ; Scroll_PreparePlaneBuffersAndRegisterShadows+82   p
                btst    #2,d5
                bne.w   Scroll_FillHorizontalPlaneBuffer
                btst    #4,d5
                bne.w   Scroll_CopyHorizontalProfile
                btst    #0,d5
                bne.s   Scroll_HorizontalPlaneWriteReturn
                move.w  d0,(a0)
Scroll_HorizontalPlaneWriteReturn:                      ; was: locret_104AE
                rts
; End of function Scroll_WriteHorizontalPlaneBuffer
; Populate one plane's vertical-scroll entries according to its mode flags
Scroll_WriteVerticalPlaneBuffer:                        ; was: sub_104B0
                                        ; Scroll_PreparePlaneBuffersAndRegisterShadows+98   j
                btst    #3,d5
                bne.w   Scroll_FillVerticalColumnEntries
                btst    #5,d5
                bne.w   Scroll_CopyVerticalColumnProfile
                btst    #1,d5
                bne.s   Scroll_VerticalPlaneWriteReturn
                move.w  d0,(a0)
Scroll_VerticalPlaneWriteReturn:                        ; was: locret_104C8
                rts
; ---------------------------------------------------------------------------
Scroll_FillHorizontalPlaneBuffer:                       ; was: loc_104CA
                cmpi.b  #2,d3
                beq.w   Scroll_FillHorizontalCellEntries
                move.w  #6,d7
Scroll_FillHorizontalLineEntriesLoop:                   ; was: loc_104D6
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                move.w  d0,$10(a0)
                move.w  d0,$14(a0)
                move.w  d0,$18(a0)
                move.w  d0,$1C(a0)
                move.w  d0,$20(a0)
                move.w  d0,$24(a0)
                move.w  d0,$28(a0)
                move.w  d0,$2C(a0)
                move.w  d0,$30(a0)
                move.w  d0,$34(a0)
                move.w  d0,$38(a0)
                move.w  d0,$3C(a0)
                move.w  d0,$40(a0)
                move.w  d0,$44(a0)
                move.w  d0,$48(a0)
                move.w  d0,$4C(a0)
                move.w  d0,$50(a0)
                move.w  d0,$54(a0)
                move.w  d0,$58(a0)
                move.w  d0,$5C(a0)
                move.w  d0,$60(a0)
                move.w  d0,$64(a0)
                move.w  d0,$68(a0)
                move.w  d0,$6C(a0)
                move.w  d0,$70(a0)
                move.w  d0,$74(a0)
                move.w  d0,$78(a0)
                move.w  d0,$7C(a0)
                lea     $80(a0),a0
                dbf     d7,Scroll_FillHorizontalLineEntriesLoop
                rts
; ---------------------------------------------------------------------------
Scroll_FillHorizontalCellEntries:                       ; was: loc_1055E
                move.w  d0,(a0)
                move.w  d0,$20(a0)
                move.w  d0,$40(a0)
                move.w  d0,$60(a0)
                move.w  d0,$80(a0)
                move.w  d0,$A0(a0)
                move.w  d0,$C0(a0)
                move.w  d0,$E0(a0)
                move.w  d0,$100(a0)
                move.w  d0,$120(a0)
                move.w  d0,$140(a0)
                move.w  d0,$160(a0)
                move.w  d0,$180(a0)
                move.w  d0,$1A0(a0)
                move.w  d0,$1C0(a0)
                move.w  d0,$1E0(a0)
                move.w  d0,$200(a0)
                move.w  d0,$220(a0)
                move.w  d0,$240(a0)
                move.w  d0,$260(a0)
                move.w  d0,$280(a0)
                move.w  d0,$2A0(a0)
                move.w  d0,$2C0(a0)
                move.w  d0,$2E0(a0)
                move.w  d0,$300(a0)
                move.w  d0,$320(a0)
                move.w  d0,$340(a0)
                move.w  d0,$360(a0)
                rts
; ---------------------------------------------------------------------------
Scroll_CopyHorizontalProfile:                           ; was: loc_105CE
                movea.w #(HorizontalScrollProfile-M68K_RAM),a2
                moveq   #0,d0
                cmpi.b  #2,d3
                beq.s   Scroll_CopyHorizontalCellProfile
                move.w  d1,d0
                move.w  #$BF,d7
                move.w  d0,d6
                bmi.s   Scroll_SelectHorizontalProfileStart
                clr.w   d6
Scroll_SelectHorizontalProfileStart:                    ; was: loc_105E6
                asl.w   #1,d0
                adda.l  d0,a2
Scroll_CopyHorizontalLineProfileLoop:                   ; was: loc_105EA
                move.w  (a2)+,(a1)
                addq.w  #4,a1
                dbf     d7,Scroll_CopyHorizontalLineProfileLoop
                move.w  -2(a2),d0
Scroll_RepeatHorizontalProfileEdgeLoop:                 ; was: loc_105F6
                move.w  d0,(a1)
                addq.w  #4,a1
                dbf     d6,Scroll_RepeatHorizontalProfileEdgeLoop
                rts
; ---------------------------------------------------------------------------
Scroll_CopyHorizontalCellProfile:                       ; was: loc_10600
                moveq   #$20,d0                         ; ' '
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                move.w  (a2)+,(a1)
                adda.w  d0,a1
                rts
; ---------------------------------------------------------------------------
Scroll_FillVerticalColumnEntries:                       ; was: loc_10664
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                move.w  d0,$10(a0)
                move.w  d0,$14(a0)
                move.w  d0,$18(a0)
                move.w  d0,$1C(a0)
                move.w  d0,$20(a0)
                move.w  d0,$24(a0)
                move.w  d0,$28(a0)
                move.w  d0,$2C(a0)
                move.w  d0,$30(a0)
                move.w  d0,$34(a0)
                move.w  d0,$38(a0)
                move.w  d0,$3C(a0)
                move.w  d0,$40(a0)
                move.w  d0,$44(a0)
                move.w  d0,$48(a0)
                move.w  d0,$4C(a0)
                rts
; ---------------------------------------------------------------------------
Scroll_CopyVerticalColumnProfile:                       ; was: loc_106B4
                movea.w #(VerticalScrollProfile-M68K_RAM),a2
                move.w  #$13,d7
Scroll_CopyVerticalColumnProfileLoop:                   ; was: loc_106BC
                move.w  (a2)+,(a0)
                addq.w  #4,a0
                dbf     d7,Scroll_CopyVerticalColumnProfileLoop
                rts
; End of function Scroll_WriteVerticalPlaneBuffer
