; Returns nonzero while an object remains inside the central flight bounds
Boss_SunsetStingCheckWithinFlightBounds:                ; was: sub_428B4
                                        ; Boss_SunsetStingSecondarySegmentFallState:Boss_SunsetStingSecondarySegmentCheckBounds   p
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                subi.w  #$780,d0
                bpl.s   Boss_SunsetStingCheckVerticalFlightBounds
                neg.w   d0
Boss_SunsetStingCheckVerticalFlightBounds:              ; was: loc_428C4
                cmpi.w  #$100,d0
                bcc.s   Boss_SunsetStingReturnOutsideFlightBounds
                move.w  $14(a5),d0
                subi.w  #$F0,d0
                bpl.s   Boss_SunsetStingCompareVerticalFlightBounds
                neg.w   d0
Boss_SunsetStingCompareVerticalFlightBounds:            ; was: loc_428D6
                cmpi.w  #$A0,d0
                bcs.s   Boss_SunsetStingCheckFlightBoundsReturn
Boss_SunsetStingReturnOutsideFlightBounds:              ; was: loc_428DC
                moveq   #0,d0
Boss_SunsetStingCheckFlightBoundsReturn:                ; was: locret_428DE
                rts
; End of function Boss_SunsetStingCheckWithinFlightBounds
; Updates wave distortion screen effect
Boss_SunsetStingUpdateWaveScreen:                       ; was: sub_428E0
                cmpi.b  #$FF,(a4)
                bne.s   Boss_SunsetStingUpdateWaveEffect
                move.w  #$60,(HScrollBuffer).w          ; '`'
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingUpdateWaveEffect:                       ; was: loc_428EE
                move.l  $10(a3),d0
                btst    #0,(a4)
                beq.w   Boss_SunsetStingBuildWaveTransitionBuffer
                lea     (SunsetStingWaveTableEnd).w,a0
                moveq   #$A,d7
Boss_SunsetStingFillWaveLeadBufferLoop:                 ; was: loc_42900
                move.l  d0,-(a0)
                move.l  d0,-(a0)
                move.l  d0,-(a0)
                move.l  d0,-(a0)
                dbf     d7,Boss_SunsetStingFillWaveLeadBufferLoop
                moveq   #$1B,d7
                move.l  $58(a5),d1
                move.l  d1,d2
                asr.l   #4,d2
Boss_SunsetStingGenerateWaveCurveLoop:                  ; was: loc_42916
                move.l  d0,-(a0)
                add.l   d1,d0
                add.l   d2,d1
                move.l  d0,-(a0)
                add.l   d1,d0
                add.l   d2,d1
                dbf     d7,Boss_SunsetStingGenerateWaveCurveLoop
                move.l  d0,$10(a5)
                lea     (HScrollBuffer).w,a0
                move.w  $14(a5),d0
                move.w  d0,d1
                subi.w  #$AC,d1
                move.w  d1,(SecondaryCameraYPos).w
                subi.w  #$94,d0
                lsl.w   #2,d0
                adda.w  d0,a0
                move.w  $10(a5),d0
                moveq   #9,d7
Boss_SunsetStingFillWaveControllerRowsLoop:             ; was: loc_4294A
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                lea     $10(a0),a0
                dbf     d7,Boss_SunsetStingFillWaveControllerRowsLoop
                lea     (SunsetStingWaveTable).w,a1
                moveq   #$18,d7
Boss_SunsetStingMergeWaveRowsLoop:                      ; was: loc_42966
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                move.w  (a1),(a0)
                move.w  4(a1),4(a0)
                move.w  8(a1),8(a0)
                move.w  $C(a1),$C(a0)
                lea     $10(a0),a0
                lea     $10(a1),a1
                dbf     d7,Boss_SunsetStingMergeWaveRowsLoop
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingBuildWaveTransitionBuffer:              ; was: loc_42996
                swap    d0
                move.w  d0,(HScrollBuffer).w
                lea     (SunsetStingWaveOffsets).w,a0
                moveq   #0,d0
                move.w  #$158,d7
                sub.w   $14(a3),d7
                lsr.w   #1,d7
                move.w  #$1E0,d2
Boss_SunsetStingFillWaveTransitionTailLoop:             ; was: loc_429B0
                move.w  d2,-(a0)
                addq.w  #2,d2
                dbf     d7,Boss_SunsetStingFillWaveTransitionTailLoop
                move.w  $14(a3),d0
                subi.w  #$71,d0                         ; 'q'
                move.l  d0,d1
                subi.w  #$AC,d0
                neg.w   d0
                move.w  $14(a5),d2
                sub.w   d2,d1
                beq.s   Boss_SunsetStingFillRemainingWaveRowsLoop
                move.w  d1,d7
                addi.w  #$48,d7                         ; 'H'
                asr.w   #1,d7
                subq.w  #1,d7
                tst.w   d1
                bpl.s   Boss_SunsetStingCalculateWaveInterpolationStep
                neg.w   d1
                moveq   #0,d2
Boss_SunsetStingCalculateWaveInterpolationStep:         ; was: loc_429E2
                asl.w   #8,d1
                divs.w  d7,d1
                ext.l   d1
                tst.w   d2
                bne.s   Boss_SunsetStingOrientWaveInterpolationStep
                neg.l   d1
Boss_SunsetStingOrientWaveInterpolationStep:            ; was: loc_429EE
                asl.l   #8,d1
Boss_SunsetStingWriteWaveInterpolationLoop:             ; was: loc_429F0
                swap    d0
                add.l   d1,d0
                swap    d0
                move.w  d0,-(a0)
                cmpa.l  #RasterStagingBuffer,a0
                ble.s   Boss_SunsetStingUpdateWaveScreenReturn
                dbf     d7,Boss_SunsetStingWriteWaveInterpolationLoop
Boss_SunsetStingFillRemainingWaveRowsLoop:              ; was: loc_42A04
                                        ; Boss_SunsetStingUpdateWaveScreen+12C   j
                move.w  d0,-(a0)
                cmpa.l  #RasterStagingBuffer,a0
                bne.s   Boss_SunsetStingFillRemainingWaveRowsLoop
Boss_SunsetStingUpdateWaveScreenReturn:                 ; was: locret_42A0E
                rts
; End of function Boss_SunsetStingUpdateWaveScreen
