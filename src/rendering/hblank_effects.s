VBlank_Epsilon1ScrollEffect:                            ; was: sub_195C
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_Epsilon1ScrollEffect_Update
                addq.w  #4,(RasterEffectInitState).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_ApplyEpsilon1VScrollAndPlaneMode_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_Epsilon1ScrollEffect_Update:                     ; was: loc_198A
                move.w  (Epsilon1TransitionY).w,d1
                neg.w   d1
                add.w   (PlaneAShakeOffset).w,d1
                move.w  d1,d0
                neg.w   d0
                move.w  d0,(Epsilon1VScrollValue).w
                addi.w  #$DF,d1
                cmpi.w  #$E2,d1
                bmi.s   VBlank_Epsilon1ScrollEffect_ApplyRegisters
                move.w  #$E2,d1
VBlank_Epsilon1ScrollEffect_ApplyRegisters:             ; was: loc_19AA
                andi.w  #$FF,d1
                move.b  d1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg11Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg4Shadow).w,(VDP_CTRL).l
                rts
; End of function VBlank_Epsilon1ScrollEffect
; ---------------------------------------------------------------------------
HBlank_ApplyEpsilon1VScrollAndPlaneMode_InstallList:    dc.w    0  ; LoadFuncToRAM  ; was: stru_19CC
                dc.l    HBlank_ApplyEpsilon1VScrollAndPlaneMode_CopyLength  ; ROM source
                dc.w    $EE00                           ; RAM destination
                dc.w    $FFFF                           ; end of list
HBlank_ApplyEpsilon1VScrollAndPlaneMode_CopyLength: dc.w    $200  ; was: word_19D6

; Writes the computed vertical scroll to VSRAM slot 2, then switches
; VDP register 11 and plane A's name-table base after a fixed delay
HBlank_ApplyEpsilon1VScrollAndPlaneMode:                ; was: sub_19D8
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (Epsilon1VScrollValue).w,(VDP_DATA).l
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  #$8B00,(VDP_CTRL).l
                move.w  #$8402,(VDP_CTRL).l
                rte
; End of function HBlank_ApplyEpsilon1VScrollAndPlaneMode
; Installs an HBlank handler that streams buffered VDP control words
VBlank_InitBufferedVDPControlEffect:                    ; was: sub_1A8E
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitBufferedVDPControlEffect_ApplyRegisters
                addq.w  #4,(RasterEffectInitState).w
                move.b  #3,(VDPReg10Shadow+1).w
                lea     HBlank_WriteVDPControl_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
VBlank_InitBufferedVDPControlEffect_ApplyRegisters:     ; was: loc_1AB2
                move.w  (VDPReg7Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg12Shadow).w,(VDP_CTRL).l
                movea.w #(RasterStagingBuffer-M68K_RAM),a6
                rts
; End of function VBlank_InitBufferedVDPControlEffect
; ---------------------------------------------------------------------------
HBlank_WriteVDPControl_InstallList: dc.w    0           ; field_0  ; was: stru_1AC8
                dc.l    HBlank_WriteVDPControl_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteVDPControl_CopyLength:  dc.w    $20         ; was: word_1AD2

; Writes the next buffered word to the VDP control port
HBlank_WriteVDPControl:                                 ; was: sub_1AD4
                move.w  (a6)+,(VDP_CTRL).l
                rte
; End of function HBlank_WriteVDPControl
; Installs Destroyer Proto's buffered VScroll-0 HBlank handler and selects
; the buffer at $FFFF9C00
VBlank_InitDestroyerProtoVScrollEffect:                 ; was: sub_1ADC
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitDestroyerProtoVScrollEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitDestroyerProtoVScrollEffect_SelectBuffer:    ; was: loc_1B0E
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     (RasterStagingBuffer).w,a6
                rts
; End of function VBlank_InitDestroyerProtoVScrollEffect
; Installs Z-Leo's buffered raster-command handler and selects the command
; stream at $FFFF9E40
VBlank_InitZLeoRasterEffect:                            ; was: sub_1B24
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitZLeoRasterEffect_UpdateRegisters
                addq.w  #4,(RasterEffectInitState).w
                move.b  #0,(VDPReg10Shadow+1).w
                lea     HBlank_ApplyZLeoRasterCommands_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitZLeoRasterEffect_UpdateRegisters:            ; was: loc_1B50
                move.w  (VDPReg11Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg2Shadow).w,(VDP_CTRL).l
                lea     (ZLeoRasterCommands).w,a6
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                rts
; End of function VBlank_InitZLeoRasterEffect
; ---------------------------------------------------------------------------
HBlank_ApplyZLeoRasterCommands_InstallList: dc.w    0   ; LoadFuncToRAM  ; was: stru_1B6E
                dc.l    HBlank_ApplyZLeoRasterCommands_CopyLength  ; ROM source
                dc.w    $EE00                           ; RAM destination
                dc.w    $FFFF                           ; end of list
HBlank_ApplyZLeoRasterCommands_CopyLength:  dc.w    $200  ; was: word_1B78

; Consumes Z-Leo's VDP-control and VScroll command stream after a fixed delay
HBlank_ApplyZLeoRasterCommands:                         ; was: sub_1B7A
                move.w  (a6)+,(VDP_CTRL).l
                move.l  #$40000010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                move.w  (a6)+,(VDP_CTRL).l
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  (a6)+,(VDP_CTRL).l
                rte
; End of function HBlank_ApplyZLeoRasterCommands
; Installs the Seven Force intro's delayed window-position HBlank handler
VBlank_InitSevenForceWindowEffect:                      ; was: sub_1C1E
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitSevenForceWindowEffect_UpdateRegisters
                addq.w  #4,(RasterEffectInitState).w
                move.b  #$80,(VDPReg10Shadow+1).w
                lea     HBlank_SetWindowPositionAfterDelay_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitSevenForceWindowEffect_UpdateRegisters:      ; was: loc_1C4A
                move.w  (VDPReg2Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg4Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg17Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg18Shadow).w,(VDP_CTRL).l
                rts
; End of function VBlank_InitSevenForceWindowEffect
; ---------------------------------------------------------------------------
HBlank_SetWindowPositionAfterDelay_InstallList: dc.w    0  ; LoadFuncToRAM  ; was: stru_1C6C
                dc.l    HBlank_SetWindowPositionAfterDelay_CopyLength  ; ROM source
                dc.w    $EE00                           ; RAM destination
                dc.w    $FFFF                           ; end of list
HBlank_SetWindowPositionAfterDelay_CopyLength:  dc.w    $200  ; was: word_1C76

; Writes VDP register 17 ($910A) and register 18 ($9200) after a fixed delay
HBlank_SetWindowPositionAfterDelay:                     ; was: sub_1C78
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  #$910A,(VDP_CTRL).l
                move.w  #$9200,(VDP_CTRL).l
                rte
; End of function HBlank_SetWindowPositionAfterDelay
; Writes one buffered word to the VRAM horizontal-scroll table at $F000 and
; one buffered word to VSRAM slot 0
HBlank_WriteHScrollAndVScroll:                          ; was: sub_1D0A
                ori.w   #$46FC,d0
                move.l  d0,-(a3)
                move.l  #$70000083,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                move.l  #$40000010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                rte
; End of function HBlank_WriteHScrollAndVScroll
; Queues DMA commands to clear VRAM tiles without data
