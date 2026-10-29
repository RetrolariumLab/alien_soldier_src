; Updates shared line offsets and copies them into Shield Viper's V-scroll plane
StageTransition_UpdateShieldViperVScroll:               ; was: sub_FC74
                                        ; StageTransition_UpdateShieldViperBackdrop+4   p
                bsr.w   StageTransition_BuildBossBackdropLineOffsets
                movea.w #(HScrollPlaneARow96-M68K_RAM),a1
                movea.w #(ActiveRasterBuffer-M68K_RAM),a0
                moveq   #$7F,d7
StageTransition_CopyShieldViperVScrollLoop:             ; was: loc_FC82
                move.w  (a0)+,(a1)
                addq.w  #4,a1
                dbf     d7,StageTransition_CopyShieldViperVScrollLoop
                rts
; End of function StageTransition_UpdateShieldViperVScroll
; Builds per-line offsets shared by the three encounter-transition backdrops
StageTransition_BuildBossBackdropLineOffsets:           ; was: sub_FC8C
                                        ; sub_FD32   p
                move.l  #$FFF88000,(BackdropLineSpeed).w
                move.l  (BackdropLineSpeed).w,d0
                add.l   d0,(BackdropLinePosition).w
                move.w  (BackdropLinePosition).w,d0
                bpl.s   StageTransition_AdjustPositiveBackdropLineOffset
                addi.w  #$40,d0                         ; '@'
                bmi.s   StageTransition_StoreAdjustedBackdropLineOffset
                bra.s   StageTransition_BuildInterpolatedBackdropLineOffsets
; ---------------------------------------------------------------------------
StageTransition_AdjustPositiveBackdropLineOffset:       ; was: loc_FCAA
                subi.w  #$40,d0                         ; '@'
                bmi.s   StageTransition_BuildInterpolatedBackdropLineOffsets
StageTransition_StoreAdjustedBackdropLineOffset:        ; was: loc_FCB0
                move.w  d0,(BackdropLinePosition).w
StageTransition_BuildInterpolatedBackdropLineOffsets:   ; was: loc_FCB4
                                        ; StageTransition_BuildBossBackdropLineOffsets+22   j
                move.l  (BackdropLinePosition).w,d0
                divs.w  #$7000,d0
                ext.l   d0
                asl.l   #8,d0
                movea.w #(BackdropLineOffsetsEnd-M68K_RAM),a0
                move.l  (BackdropLinePosition).w,d1
                moveq   #$5F,d7                         ; '_'
StageTransition_FillInterpolatedBackdropLineOffsets:    ; was: loc_FCCA
                swap    d1
                move.w  d1,-(a0)
                swap    d1
                sub.l   d0,d1
                dbf     d7,StageTransition_FillInterpolatedBackdropLineOffsets
                move.l  (BackdropLineSpeed).w,d0
                add.l   d0,(BackdropTailPosition).w
                move.w  (BackdropTailPosition).w,d1
                asr.w   #4,d1
                moveq   #$17,d7
StageTransition_FillBackdropTailLineOffsets:            ; was: loc_FCE6
                move.w  d1,-(a0)
                dbf     d7,StageTransition_FillBackdropTailLineOffsets
                move.w  (BackdropLinePhase).w,d1
                move.w  d1,-(a0)
                rts
; End of function StageTransition_BuildBossBackdropLineOffsets
; Updates the shared Destroyer Proto and Shield Viper backdrop palette fade
StageTransition_UpdateBossBackdropPaletteFade:          ; was: sub_FCF4
                                        ; StageTransition_UpdateDestroyerProtoBackdropFade+8   p
                tst.w   (BossBackdropFadeLevel).w
                bne.s   StageTransition_AdvanceBossBackdropPaletteFade
                rts
; ---------------------------------------------------------------------------
StageTransition_AdvanceBossBackdropPaletteFade:         ; was: loc_FCFC
                btst    #0,(FrameCounter+1).w
                bne.s   StageTransition_ApplyBossBackdropPaletteFade
                subq.w  #1,(BossBackdropFadeLevel).w
StageTransition_ApplyBossBackdropPaletteFade:           ; was: loc_FD08
                                        ; StageTransition_CompleteShieldViperFade   p
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                move.w  #$E000,d7
                move.w  (BossBackdropFadeLevel).w,d0
                moveq   #$3F,d5                         ; '?'
                jsr     (Gfx_ApplyFullActivePaletteFade).l
                moveq   #0,d0
                sub.w   (BossBackdropFadeLevel).w,d0
                movea.w #(PaletteActiveColor32-M68K_RAM),a0
                move.w  #$C000,d7
                moveq   #$F,d5
                jmp     (Gfx_ApplyPaletteFade).l
; End of function StageTransition_UpdateBossBackdropPaletteFade
; Builds raster workspaces shared by three encounter-transition backdrops
StageTransition_BuildBossBackdropRasterBuffers:         ; was: sub_FD32
                                        ; StageTransition_UpdatePostDestroyerProtoScroll+8   p
                bsr.w   StageTransition_BuildBossBackdropLineOffsets
                movea.w #(BossBackdropWorkBuffer-M68K_RAM),a0
                movea.w #(BossBackdropCopySource-M68K_RAM),a1
                moveq   #6,d7
StageTransition_CopyBossBackdropWorkspace:              ; was: loc_FD40
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                dbf     d7,StageTransition_CopyBossBackdropWorkspace
                move.w  (BackdropPositionA).w,d0
                subi.w  #$20,d0                         ; ' '
                move.w  d0,(BackdropBandOffset).w
                moveq   #$20,d0                         ; ' '
                move.w  (BackdropPositionA).w,d1
                asr.w   #1,d1
                sub.w   d1,d0
                move.w  d0,d2
                move.w  d0,d3
                addi.w  #$20,d2                         ; ' '
                move.w  #$80,d5
                moveq   #$60,d6                         ; '`'
                move.l  (BackdropVelocityB).w,d0
                asr.l   #1,d0
                move.l  (BackdropLinePhase).w,d1
                add.l   d0,d1
                move.l  d1,(BackdropLinePhase).w
                swap    d1
                movea.w #(BossBackdropBandBufferB-M68K_RAM),a0
                movea.w #(BossBackdropBandBufferA-M68K_RAM),a1
                moveq   #$17,d7
StageTransition_FillBossBackdropBandBuffers:            ; was: loc_FD94
                move.w  d3,d0
                move.w  d2,d2
                bmi.s   StageTransition_UseBossBackdropBandFallback
                cmp.w   d5,d2
                bmi.s   StageTransition_StoreBossBackdropBandValues
StageTransition_UseBossBackdropBandFallback:            ; was: loc_FD9E
                move.w  d6,d0
StageTransition_StoreBossBackdropBandValues:            ; was: loc_FDA0
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a1)+
                move.w  d1,(a1)+
                move.w  d1,(a1)+
                addq.w  #8,d2
                subq.w  #8,d6
                dbf     d7,StageTransition_FillBossBackdropBandBuffers
                cmpi.w  #$60,(BackdropRasterSpan).w     ; '`'
                bpl.s   StageTransition_CalculateExpandedBackdropStep
                move.w  (BackdropRasterSpan).w,d1
                bne.s   StageTransition_CalculateCompressedBackdropStep
                move.l  #$FFFE0000,d0
                bra.s   StageTransition_ConfigureBossBackdropRasterFill
; ---------------------------------------------------------------------------
StageTransition_CalculateCompressedBackdropStep:        ; was: loc_FDCE
                move.l  #$6000,d0
                divu.w  d1,d0
                subi.w  #$100,d0
                ext.l   d0
                asl.l   #8,d0
                asl.l   #1,d0
                bra.s   StageTransition_ConfigureBossBackdropRasterFill
; ---------------------------------------------------------------------------
StageTransition_CalculateExpandedBackdropStep:          ; was: loc_FDE2
                move.l  (BackdropRasterSpan).w,d0
                divu.w  #$3000,d0
                subi.w  #$200,d0
                neg.w   d0
                ext.l   d0
                asl.l   #7,d0
StageTransition_ConfigureBossBackdropRasterFill:        ; was: loc_FDF4
                                        ; StageTransition_BuildBossBackdropRasterBuffers+AE   j
                moveq   #0,d1
                move.w  (BackdropBandOffset).w,d1
                neg.w   d1
                swap    d1
                move.w  (BackdropBandOffset).w,d2
                andi.w  #$FFFE,d2
                addi.w  #$8E,d2
                addi.w  #-$6500,d2
                movea.w d2,a0
                move.w  (BackdropBandOffset).w,d2
                andi.w  #$FFFE,d2
                addi.w  #$8E,d2
                addi.w  #-$6800,d2
                movea.w d2,a2
                movea.w #(BossBackdropLeadBands-M68K_RAM),a1
                move.w  (BackdropBandOffset).w,d3
                neg.w   d3
                moveq   #8,d7
StageTransition_CopyBossBackdropLeadingBands:           ; was: loc_FE2E
                cmpa.w  #$9C00,a0
                bpl.s   StageTransition_BossBackdropRasterBuildReturn
                move.w  d3,(a0)+
                move.w  (a1)+,d4
                move.w  d4,(a2)+
                dbf     d7,StageTransition_CopyBossBackdropLeadingBands
                movea.w #(BossBackdropBandSource-M68K_RAM),a1
                move.w  (BackdropBandOffset).w,d2
                neg.w   d2
                move.w  #$9C00,d6
StageTransition_FillBossBackdropRemainingBands:         ; was: loc_FE4C
                cmpa.w  d6,a0
                bpl.s   StageTransition_BossBackdropRasterBuildReturn
                swap    d1
                move.w  d1,(a0)+
                move.w  d1,d3
                swap    d1
                add.l   d0,d1
                sub.w   d2,d3
                asl.w   #1,d3
                move.w  (a1,d3.w),(a2)+
                subq.w  #2,d2
                bra.s   StageTransition_FillBossBackdropRemainingBands
; ---------------------------------------------------------------------------
StageTransition_BossBackdropRasterBuildReturn:          ; was: locret_FE66
                                        ; StageTransition_BuildBossBackdropRasterBuffers+11C   j
                rts
; End of function StageTransition_BuildBossBackdropRasterBuffers
; Fills and queues the next Shield Viper backdrop tile row
StageTransition_QueueShieldViperBackdropRow:            ; was: sub_FE68
                movea.w #(ShieldViperBackdropRow-M68K_RAM),a0
                movea.w a0,a1
                moveq   #$3F,d7                         ; '?'
                move.w  (ShieldViperRowIndex).w,d0
                addi.w  #-$7E2C,d0
StageTransition_FillShieldViperBackdropRow:             ; was: loc_FE78
                move.w  d0,(a1)+
                dbf     d7,StageTransition_FillShieldViperBackdropRow
                move.w  (ShieldViperRowVRAMPos).w,d0
                addi.w  #-$1800,d0
                addi.w  #$80,(ShieldViperRowVRAMPos).w
                addq.w  #1,(ShieldViperRowIndex).w
                move.w  #$8F02,d3
                move.l  #$94009340,d4
                jmp     VDP_QueueCommand_Build
; End of function StageTransition_QueueShieldViperBackdropRow
