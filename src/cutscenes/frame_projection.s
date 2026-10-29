CutsceneProjection_Initialize:                          ; was: sub_260A2
                                        ; XiTigerCutscene_LoadAssets+34   j
                move.l  #$1FFFE,(CutsceneScaleStep).w
                move.w  #$1E,(CutsceneOffsetCenter).w
                move.w  #$B,(CutsceneRowLoopLimit).w
                move.w  #0,(CutsceneVerticalOffset).w
                move.w  #8,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.w  #2,(RasterLayoutOffset).w
                rts
; End of function CutsceneProjection_Initialize
; Resamples a cutscene frame, queues its row transfers, and builds the line-offset table
CutsceneProjection_BuildFrame:                          ; was: sub_260CE
                                        ; XiTigerCutscene_WaitBeforeReveal+44   j
                movea.l #CutsceneFrameSourceBuffer,a0
                move.w  #$9400,(CutsceneRowSource).w
                move.w  #$C400,(CutsceneRowVRAM).w
                move.l  (CutsceneScaleStep).w,d0
                move.l  d0,(CutsceneScaleSnapshot).w
                bra.w   *+4
; ---------------------------------------------------------------------------
CutsceneProjection_BuildFrame_InitializeCopy:           ; was: loc_260EC
                moveq   #0,d3
                moveq   #0,d4
                moveq   #$13,d6
CutsceneProjection_BuildFrame_CopyColumnPairLoop:       ; was: loc_260F2
                movea.w (CutsceneRowSource).w,a1
                movea.w (CutsceneRowSource).w,a2
                lea     $26(a1),a1
                lea     $28(a2),a2
                suba.w  d3,a1
                adda.w  d3,a2
                add.l   d0,d4
                move.l  d4,d1
                swap    d1
                andi.w  #$FFFE,d1
                move.w  d1,d2
                neg.w   d1
                move.w  #$80,d5
                move.w  (CutsceneRowLoopLimit).w,d7
CutsceneProjection_BuildFrame_CopyColumnWordsLoop:      ; was: loc_2611C
                move.w  $26(a0,d1.w),(a1)
                move.w  $28(a0,d2.w),(a2)
                add.w   d5,d1
                add.w   d5,d2
                adda.w  d5,a1
                adda.w  d5,a2
                dbf     d7,CutsceneProjection_BuildFrame_CopyColumnWordsLoop
                addq.w  #2,d3
                dbf     d6,CutsceneProjection_BuildFrame_CopyColumnPairLoop
                movea.w (VDPCommandQueueHead).w,a4
                move.w  (CutsceneRowVRAM).w,d0
                move.w  (CutsceneRowLoopLimit).w,d7
CutsceneProjection_BuildFrame_QueueTransferLoop:        ; was: loc_26142
                move.w  #$83,-(a4)
                move.w  d0,d4
                andi.w  #$3FFE,d4
                ori.w   #$4000,d4
                move.w  d4,-(a4)
                move.b  (CutsceneRowSource).w,d4
                move.b  (CutsceneRowSource+1).w,d5
                asr.b   #1,d4
                roxr.b  #1,d5
                move.b  d5,-(a4)
                move.b  #$95,-(a4)
                move.b  d4,-(a4)
                move.b  #$96,-(a4)
                move.l  #$8F02977F,-(a4)
                move.l  #$94009328,-(a4)
                addi.w  #$80,d0
                addi.w  #$80,(CutsceneRowSource).w
                dbf     d7,CutsceneProjection_BuildFrame_QueueTransferLoop
                move.w  a4,(VDPCommandQueueHead).w
                moveq   #$F,d0
                move.l  (CutsceneScaleSnapshot).w,d1
                movea.w #(CutsceneLineOffsetTable-M68K_RAM),a1
                adda.w  (CutsceneOffsetCenter).w,a1
                movea.w a1,a2
                subi.l  #$20000,d1
                asl.l   #2,d1
                move.w  #$FFFF,d4
                move.w  (CutsceneVerticalOffset).w,d5
                moveq   #0,d6
                moveq   #0,d7
                sub.l   d1,d7
CutsceneProjection_BuildFrame_BuildLineOffsetsLoop:     ; was: loc_261AE
                cmpa.w  #$9F80,a1
                bmi.s   CutsceneProjection_BuildFrame_WriteRightLineOffset
                sub.l   d1,d6
                move.l  d6,d3
                swap    d3
                and.w   d4,d3
                add.w   d5,d3
                move.w  d3,-(a1)
CutsceneProjection_BuildFrame_WriteRightLineOffset:     ; was: loc_261C0
                cmpa.w  #$9FC0,a2
                bpl.s   CutsceneProjection_BuildFrame_AdvanceLineOffsetLoop
                add.l   d1,d7
                move.l  d7,d3
                swap    d3
                and.w   d4,d3
                add.w   d5,d3
                move.w  d3,(a2)+
CutsceneProjection_BuildFrame_AdvanceLineOffsetLoop:    ; was: loc_261D2
                dbf     d0,CutsceneProjection_BuildFrame_BuildLineOffsetsLoop
                rts
; End of function CutsceneProjection_BuildFrame
; Initializes scrolling effect parameters for stage background layer
