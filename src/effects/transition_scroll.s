Effect_SetupScrollPointers:
                bra.s   TransitionEffect_SetOutputBufferPointers  ; was: sub_26C58
; End of function Effect_SetupScrollPointers
; Sets d5 to alternate sine table address FFFF9B00 and branches to common scroll processing
Orphaned_ScrollSineTable1:
                move.l  #$FFFF9B00,d5                   ; was: sub_26C5A
                bra.s   Orphaned_BuildSineScrollBuffer
; End of function Orphaned_ScrollSineTable1
; Processes scroll effect using sine table at Effect_TransitionSineTable, interpolating 63 values based on TransitionProgress
Orphaned_ScrollSineTable2:
                move.l  #Effect_TransitionSineTable,d5  ; was: sub_26C62
Orphaned_BuildSineScrollBuffer:                         ; was: loc_26C68
                movea.w #(TransitionRampBuffer-M68K_RAM),a0
                movea.w #(TransitionRampBuffer-M68K_RAM),a2
                moveq   #$FFFFFFFE,d6
                moveq   #$3E,d7                         ; '>'
                move.w  (TransitionProgress).w,d1
                asl.w   #8,d1
                moveq   #0,d3
                move.w  (TransitionProgress).w,d2
                beq.s   Orphaned_BuildSineScrollBuffer_BeginLoop
                move.l  #$8000,d3
                divu.w  d2,d3
                andi.l  #$FFFF,d3
                asl.l   #1,d3
                asl.l   #8,d3
Orphaned_BuildSineScrollBuffer_BeginLoop:               ; was: loc_26C94
                moveq   #0,d2
Orphaned_BuildSineScrollBuffer_Loop:                    ; was: loc_26C96
                cmpi.l  #$FE0000,d2
                bpl.s   Orphaned_BuildSineScrollBuffer_StoreSample
                add.l   d3,d2
                move.l  d2,d4
                swap    d4
                ext.l   d4
                move.l  d5,d0
                sub.l   d4,d0
                and.l   d6,d0
                movea.l d0,a1
Orphaned_BuildSineScrollBuffer_StoreSample:             ; was: loc_26CAE
                move.w  (a1),d0
                muls.w  d1,d0
                swap    d0
                move.w  d0,-(a0)
                move.w  d0,(a2)+
                dbf     d7,Orphaned_BuildSineScrollBuffer_Loop
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a2
                movea.w #(TransitionVScrollBuffer-M68K_RAM),a3
                rts
; End of function Orphaned_ScrollSineTable2
; Fills scroll buffer starting at offset -6C00 with value from TransitionOriginXY+2, repeating TransitionMaskStep times
Effect_FillScrollBuffer:                                ; was: sub_26CCA
                move.w  (TransitionProgress).w,d0
                andi.w  #$1FE,d0
                addi.w  #-$6C00,d0
                movea.w d0,a0
                move.w  (TransitionOriginXY+2).w,d1
                move.w  (TransitionMaskStep).w,d7
Effect_FillScrollBuffer_Loop:                           ; was: loc_26CE0
                move.w  d1,(a0)+
                dbf     d7,Effect_FillScrollBuffer_Loop
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a2
                movea.w #(TransitionVScrollBuffer-M68K_RAM),a3
                rts
; End of function Effect_FillScrollBuffer
; Processes vertical scroll values for 127 entries, clamping to 0-160 range and computing scroll offsets
Orphaned_ProcessVerticalScroll:
                moveq   #1,d1                           ; was: sub_26CF4
                move.w  #$FE,d2
                move.w  #$FFFE,d3
                move.w  #$120,d4
                moveq   #$7E,d7                         ; '~'
Orphaned_ProcessVerticalScroll_Loop:                    ; was: loc_26D04
                move.w  (a0)+,d0
                asl.w   #1,d0
                move.w  d4,d5
                sub.w   d0,d5
                and.w   d3,d5
                bpl.s   Orphaned_ProcessVerticalScroll_CheckUpperBound
                asr.w   #1,d5
                add.w   d5,d0
                bpl.s   Orphaned_ProcessVerticalScroll_ClampLow
                moveq   #0,d0
Orphaned_ProcessVerticalScroll_ClampLow:                ; was: loc_26D18
                moveq   #0,d5
                bra.s   Orphaned_ProcessVerticalScroll_Store
; ---------------------------------------------------------------------------
Orphaned_ProcessVerticalScroll_CheckUpperBound:         ; was: loc_26D1C
                cmpi.w  #$140,d5
                bmi.s   Orphaned_ProcessVerticalScroll_AdjustCenter
                moveq   #0,d5
                moveq   #0,d0
                bra.s   Orphaned_ProcessVerticalScroll_Store
; ---------------------------------------------------------------------------
Orphaned_ProcessVerticalScroll_AdjustCenter:            ; was: loc_26D28
                move.w  d0,d6
                add.w   d5,d6
                cmpi.w  #$A0,d6
                bmi.s   Orphaned_ProcessVerticalScroll_Store
                subi.w  #$A0,d0
                add.w   d5,d0
                bpl.s   Orphaned_ProcessVerticalScroll_Store
                moveq   #0,d5
                moveq   #0,d0
Orphaned_ProcessVerticalScroll_Store:                   ; was: loc_26D3E
                                        ; Orphaned_ProcessVerticalScroll+32   j
                move.w  d5,(a3)+
                move.w  d5,(a3)+
                sub.w   d1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                addq.w  #2,d1
                dbf     d7,Orphaned_ProcessVerticalScroll_Loop
                rts
; End of function Orphaned_ProcessVerticalScroll
; Processes horizontal scroll data for 127 scanlines, calculating doubled scroll offsets with 160-pixel wraparound
Orphaned_ProcessHorizontalScroll:
                moveq   #1,d1                           ; was: sub_26D50
                move.w  #$FE,d2
                move.w  #$FFFE,d3
                move.w  #$A0,d4
                moveq   #$7E,d7                         ; '~'
Orphaned_ProcessHorizontalScroll_Loop:                  ; was: loc_26D60
                move.w  (a0),d0
                sub.w   d1,d0
                asl.w   #1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                move.w  (a0)+,d0
                asl.w   #1,d0
                move.w  d4,d5
                sub.w   d0,d5
                and.w   d3,d5
                move.w  d5,(a3)+
                move.w  d5,(a3)+
                addq.w  #1,d1
                dbf     d7,Orphaned_ProcessHorizontalScroll_Loop
                rts
; End of function Orphaned_ProcessHorizontalScroll
; Processes scroll with conditional vertical calculation based on TransitionOriginXY flag, quadruples values if enabled
Effect_ProcessConditionalScroll:                        ; was: sub_26D80
                moveq   #1,d1
                move.w  #$FE,d2
                move.w  #$A0,d4
                moveq   #$7E,d7                         ; '~'
Effect_ProcessConditionalScroll_Loop:                   ; was: loc_26D8C
                move.w  (a0)+,d0
                sub.w   d1,d0
                asl.w   #1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                tst.w   (TransitionOriginXY).w
                beq.s   Effect_ProcessConditionalScroll_Next
                move.w  -2(a0),d0
                asl.w   #2,d0
                move.w  #$140,d3
                sub.w   d0,d3
                move.w  d3,(a3)+
                move.w  d3,(a3)+
Effect_ProcessConditionalScroll_Next:                   ; was: loc_26DAC
                addq.w  #1,d1
                dbf     d7,Effect_ProcessConditionalScroll_Loop
                rts
; End of function Effect_ProcessConditionalScroll
; Simple scroll processor that applies constant vertical offset from TransitionOriginXY to 127 horizontal scroll entries
Effect_ProcessSimpleScroll:                             ; was: sub_26DB4
                moveq   #1,d1
                move.w  #$FE,d2
                moveq   #$7E,d7                         ; '~'
                move.w  (TransitionOriginXY).w,d6
Effect_ProcessSimpleScroll_Loop:                        ; was: loc_26DC0
                move.w  (a0)+,d0
                sub.w   d1,d0
                asl.w   #1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                move.w  d6,(a3)+
                move.w  d6,(a3)+
                addq.w  #1,d1
                dbf     d7,Effect_ProcessSimpleScroll_Loop
                rts
; End of function Effect_ProcessSimpleScroll
; Copies seven 32-byte blocks from the active output buffer into its working copy
TransitionEffect_CopyWorkingBuffer:                     ; was: sub_26DD6
                                        ; TransitionEffect_UpdateMode2Buffers   p
                movea.w #(TransitionWorkingBuffer-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a1
                moveq   #6,d7
; End of function TransitionEffect_CopyWorkingBuffer
; Copies d7+1 blocks of 32 bytes from a1 to a0
Effect_Copy32ByteBlocks:                                ; was: sub_26DE0
                                        ; TransitionEffect_UpdateMode4Buffers+A   p
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                move.l  (a1)+,(a0)+
                dbf     d7,Effect_Copy32ByteBlocks
                rts
; End of function Effect_Copy32ByteBlocks
; Applies sine wave modulation to scroll buffer using Effect_LinearScrollBaseTable table and Math_QuarterSineTable multiplier data
Orphaned_ApplySineWaveScroll:
                movea.l #Effect_LinearScrollBaseTable,a0  ; was: sub_26DF6
                movea.w #(TransitionRasterWork-M68K_RAM),a1
                movea.l #Math_QuarterSineTable,a2
                moveq   #$7F,d7
                move.w  (TransitionOriginXY).w,d1
                andi.w  #$1FE,d1
Orphaned_ApplySineWaveScroll_Loop:                      ; was: loc_26E10
                move.w  (a0)+,d2
                mulu.w  (a2,d1.w),d2
                asl.l   #3,d2
                swap    d2
                move.w  d2,(a1)+
                addq.w  #1,d1
                andi.w  #$FE,d1
                dbf     d7,Orphaned_ApplySineWaveScroll_Loop
                rts
; End of function Orphaned_ApplySineWaveScroll
; Applies linear interpolation to scroll buffer using accumulator from TransitionOriginXY added to Effect_LinearScrollBaseTable base values
Orphaned_ApplyLinearScroll:
                movea.l #Effect_LinearScrollBaseTable,a0  ; was: sub_26E28
                movea.w #(TransitionRasterWork-M68K_RAM),a1
                moveq   #$7F,d7
                moveq   #0,d0
                move.l  (TransitionOriginXY).w,d1
Orphaned_ApplyLinearScroll_Loop:                        ; was: loc_26E3A
                add.l   d1,d0
                swap    d0
                move.w  (a0)+,d2
                add.w   d0,d2
                swap    d0
                move.w  d2,(a1)+
                dbf     d7,Orphaned_ApplyLinearScroll_Loop
                rts
; End of function Orphaned_ApplyLinearScroll
; Drives palette entry 62 in both the active and the shadow buffer: a white/blue
; strobe until TransitionProgress reaches $40, then a walk down the colour ramp
Effect_UpdateTransitionColor62:                         ; was: sub_26E4C
                                        ; TransitionEffect_Update   p
                movea.w #(PaletteActiveColor62-M68K_RAM),a1
                move.w  (TransitionProgress).w,d0
                subi.w  #$40,d0                         ; '@'
                bpl.s   Effect_UpdateTransitionColor62_SelectRampEntry
                move.w  #$EEE,d0
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_UpdateTransitionColor62_Store
                btst    #0,(RandomNumberState).w
                bne.s   Effect_UpdateTransitionColor62_Store
                move.w  #$8CE,d0
Effect_UpdateTransitionColor62_Store:                   ; was: loc_26E72
                                        ; Effect_UpdateTransitionColor62+20   j
                move.w  d0,$80(a1)
                move.w  d0,(a1)
                rts
; ---------------------------------------------------------------------------
Effect_UpdateTransitionColor62_SelectRampEntry:         ; was: loc_26E7A
                asr.w   #1,d0
                andi.w  #$1E,d0
                move.w  Effect_TransitionColorRamp(pc,d0.w),$80(a1)
                move.w  Effect_TransitionColorRamp(pc,d0.w),(a1)
                rts
; End of function Effect_UpdateTransitionColor62
; ---------------------------------------------------------------------------
Effect_TransitionColorRamp: dc.w    $EEE, $CEE, $AEE, $8EE, $6EE, $4CE, $2AE, $8E, $6E, $4E, $2E, $E, $C, $A, 8, 6  ; was: word_26E8C
                                        ; Effect_UpdateTransitionColor62+3A   r

; Clears 64 longwords of the transition pattern buffer
Effect_ClearScrollBuffer:                               ; was: sub_26EAC
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                moveq   #0,d0
                moveq   #$3F,d7                         ; '?'
Effect_ClearScrollBuffer_Loop:                          ; was: loc_26EB4
                move.l  d0,(a0)+
                dbf     d7,Effect_ClearScrollBuffer_Loop
                rts
; End of function Effect_ClearScrollBuffer
; ---------------------------------------------------------------------------
Effect_LinearScrollBaseTable:   binclude "data/other/word_26EBC.bin"  ; was: word_26EBC
Effect_LinearScrollBaseTable_End:                       ; was: word_26EBC_End
Effect_TransitionSineTable:     binclude "data/other/word_26FBC.bin"  ; was: word_26FBC
Effect_TransitionSineTable_End:                         ; was: word_26FBC_End

; Generates the transition edge and scroll output buffers in RAM
Effect_GenerateTransitionBuffers:                       ; was: sub_271BC
                movea.w #(TransitionEdgeCenter1-M68K_RAM),a0
                movea.w #(TransitionEdgeCenter1-M68K_RAM),a2
                movea.l #Effect_TransitionSineTable,a1
                move.w  #$FF00,d5
                moveq   #$FFFFFFFE,d6
                move.w  #$7E,d7                         ; '~'
                move.w  (TransitionProgress).w,d1
                asl.w   #8,d1
                asl.w   #1,d1
                moveq   #0,d3
                move.w  (TransitionProgress).w,d2
                beq.s   Effect_GenerateTransitionBuffers_BeginEdgeLoop
                move.l  (TransitionEdgeSpan).w,d3
                divu.w  d2,d3
                andi.l  #$FFFF,d3
                asl.l   #1,d3
                asl.l   #8,d3
Effect_GenerateTransitionBuffers_BeginEdgeLoop:         ; was: loc_271F4
                moveq   #0,d2
Effect_GenerateTransitionBuffers_EdgeLoop:              ; was: loc_271F6
                sub.l   d3,d2
                move.l  d2,d4
                swap    d4
                and.l   d6,d4
                cmp.w   d5,d4
                bpl.s   Effect_GenerateTransitionBuffers_ReadSample
                moveq   #0,d0
                bra.s   Effect_GenerateTransitionBuffers_StoreSample
; ---------------------------------------------------------------------------
Effect_GenerateTransitionBuffers_ReadSample:            ; was: loc_27206
                move.w  (a1,d4.w),d0
                mulu.w  d1,d0
                swap    d0
                andi.w  #$FFFE,d0
Effect_GenerateTransitionBuffers_StoreSample:           ; was: loc_27212
                move.w  d0,-(a0)
                move.w  d0,(a2)+
                dbf     d7,Effect_GenerateTransitionBuffers_EdgeLoop
                movea.w #(TransitionRasterWork-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a2
                movea.w #(TransitionVScrollBuffer-M68K_RAM),a3
                move.w  (TransitionOriginXY).w,d4
                subi.w  #$80,d4
                move.w  (TransitionOriginXY+2).w,d0
                subi.w  #$180,d0
                neg.w   d0
                andi.w  #$FFFE,d0
                adda.w  d0,a0
                moveq   #2,d1
                move.w  #$FE,d2
                moveq   #$7E,d7                         ; '~'
Effect_GenerateTransitionBuffers_OutputLoop:            ; was: loc_27246
                move.w  (a0)+,d0
                cmpa.w  #$9A02,a0
                bmi.s   Effect_GenerateTransitionBuffers_ClearOutsideRange
                cmpa.w  #$9C00,a0
                bmi.s   Effect_GenerateTransitionBuffers_CheckOffset
Effect_GenerateTransitionBuffers_ClearOutsideRange:     ; was: loc_27254
                moveq   #0,d0
Effect_GenerateTransitionBuffers_CheckOffset:           ; was: loc_27256
                move.w  d4,d5
                sub.w   d0,d5
                move.w  d5,d6
                bmi.s   Effect_GenerateTransitionBuffers_AdjustOffset
                cmpi.w  #4,d5
                bpl.s   Effect_GenerateTransitionBuffers_ClampSample
Effect_GenerateTransitionBuffers_AdjustOffset:          ; was: loc_27264
                asr.w   #1,d5
                add.w   d5,d0
                bpl.s   Effect_GenerateTransitionBuffers_ZeroOffset
Effect_GenerateTransitionBuffers_ClearSample:           ; was: loc_2726A
                moveq   #0,d0
Effect_GenerateTransitionBuffers_ZeroOffset:            ; was: loc_2726C
                moveq   #0,d5
                andi.w  #2,d6
                add.w   d6,d5
                bra.s   Effect_GenerateTransitionBuffers_StoreOutput
; ---------------------------------------------------------------------------
Effect_GenerateTransitionBuffers_ClampSample:           ; was: loc_27276
                cmpi.w  #$9E,d0
                bmi.s   Effect_GenerateTransitionBuffers_CheckUpperBound
                move.w  #$9E,d0
Effect_GenerateTransitionBuffers_CheckUpperBound:       ; was: loc_27280
                cmpi.w  #$140,d5
                bpl.s   Effect_GenerateTransitionBuffers_ClearSample
                move.w  d5,d3
                asr.w   #1,d3
                add.w   d0,d3
                cmpi.w  #$100,d3
                bmi.s   Effect_GenerateTransitionBuffers_StoreOutput
                move.w  #$140,d0
                sub.w   d5,d0
Effect_GenerateTransitionBuffers_StoreOutput:           ; was: loc_27298
                                        ; Effect_GenerateTransitionBuffers+D4   j
                move.w  d5,(a3)+
                sub.w   d1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                addq.w  #2,d1
                dbf     d7,Effect_GenerateTransitionBuffers_OutputLoop
                rts
; End of function Effect_GenerateTransitionBuffers
; Clears the transition pattern buffer and resets its progress counter
Effect_ClearTransitionPatternBuffer:                    ; was: sub_272A8
                                        ; TransitionEffect_InitializeObject+16   j
                clr.w   (TransitionMaskStep).w
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                moveq   #0,d0
                moveq   #$17,d7
Effect_ClearTransitionPatternBuffer_Loop:               ; was: loc_272B4
                move.l  d0,(a0)+
                dbf     d7,Effect_ClearTransitionPatternBuffer_Loop
                bra.w   Effect_QueueTransitionVdpRegisters
; End of function Effect_ClearTransitionPatternBuffer
; Builds the base transition pattern in the shared effect buffer
Effect_BuildTransitionPattern:                          ; was: sub_272BE
                                        ; TunnelTransition_BuildInitialPattern+C   p
                moveq   #0,d0
                move.l  #$EEEE0000,d1
                move.l  #$EEEEEEEE,d2
                move.l  d0,d3
                move.l  d1,d4
                move.l  d2,d5
Effect_BuildTransitionPattern_Write:                    ; was: loc_272D2
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                moveq   #3,d7
Effect_BuildTransitionPattern_PrefixLoop:               ; was: loc_272D8
                move.l  d2,(a0)+
                move.l  d5,(a0)+
                dbf     d7,Effect_BuildTransitionPattern_PrefixLoop
                move.l  d0,(a0)+
                move.l  d3,(a0)+
                move.l  d1,(a0)+
                move.l  d4,(a0)+
                move.l  d2,(a0)+
                move.l  d5,(a0)+
                move.l  d2,(a0)+
                move.l  d5,(a0)+
                moveq   #2,d7
Effect_BuildTransitionPattern_SuffixLoop:               ; was: loc_272F2
                move.l  d0,(a0)+
                move.l  d3,(a0)+
                dbf     d7,Effect_BuildTransitionPattern_SuffixLoop
                move.l  d1,(a0)+
                move.l  d4,(a0)+
                bra.w   Effect_QueueTransitionVdpRegisters
; End of function Effect_BuildTransitionPattern
; Initializes special scroll pattern with EEEEEEEE values for boss defeat effect, sets up 40 bytes of pattern
Effect_InitDefeatScroll:                                ; was: sub_27302
                moveq   #0,d0
                move.l  #$EEEEEEEE,d2
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0
                moveq   #7,d7
Effect_InitDefeatScroll_PrefixLoop:                     ; was: loc_27310
                move.l  d2,(a0)+
                dbf     d7,Effect_InitDefeatScroll_PrefixLoop
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                moveq   #7,d7
Effect_InitDefeatScroll_SuffixLoop:                     ; was: loc_27328
                move.l  d0,(a0)+
                dbf     d7,Effect_InitDefeatScroll_SuffixLoop
                bra.w   Effect_QueueTransitionVdpRegisters
; End of function Effect_InitDefeatScroll
; Masks individual scroll buffer byte based on TransitionMaskStep timer, using lookup table to select byte offset
Orphaned_MaskScrollByte:
                movea.w #(TransitionPatternBuffer-M68K_RAM),a0  ; was: sub_27332
                lea     Effect_TransitionMaskByteOffsets(pc),a1
                nop
                move.b  #$F,d3
                move.w  (TransitionMaskStep).w,d0
                cmpi.w  #$20,d0                         ; ' '
                bmi.s   Orphaned_MaskScrollByte_SelectNibble
                move.b  #$F0,d3
Orphaned_MaskScrollByte_SelectNibble:                   ; was: loc_2734E
                andi.w  #$1F,d0
                moveq   #0,d2
                move.b  (a1,d0.w),d2
                move.b  (a0,d2.w),d1
                and.b   d3,d1
                move.b  d1,(a0,d2.w)
                move.b  $20(a0,d2.w),d1
                and.b   d3,d1
                move.b  d1,$20(a0,d2.w)
                move.b  $40(a0,d2.w),d1
                and.b   d3,d1
                move.b  d1,$40(a0,d2.w)
Effect_QueueTransitionVdpRegisters:                     ; was: loc_27376
                                        ; Effect_BuildTransitionPattern+40   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$82,-(a1)
                move.w  #$73A0,-(a1)
                move.w  #$9500,-(a1)
                move.w  #$96CA,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009330,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function Orphaned_MaskScrollByte
; ---------------------------------------------------------------------------
Effect_TransitionMaskByteOffsets:   dc.w    $10, $111, $212, $313, $414, $515, $616, $717, $818, $919, $A1A, $B1B, $C1C, $D1D, $E1E, $F1F  ; was: word_2739C

; Applies the current transition mask to three pattern-buffer rows
Effect_ApplyTransitionMask:                             ; was: sub_273BC
                                        ; TransitionEffect_Update+2C   j
                lea     Effect_TransitionMaskPatternsA(pc),a1
                nop
                move.w  (TransitionProgress).w,d2
                asr.w   #2,d2
                andi.w  #$1C,d2
                move.l  (a1,d2.w),d0
                move.l  $20(a1,d2.w),d1
                movea.w #(TransitionPatternRow0-M68K_RAM),a0
                movea.w #(TransitionPatternRow1-M68K_RAM),a1
                movea.w #(TransitionPatternRow2-M68K_RAM),a2
                moveq   #3,d7
Effect_ApplyTransitionMask_Loop:                        ; was: loc_273E2
                move.l  (a0),d2
                move.l  (a1),d3
                move.l  (a2),d4
                and.l   d0,d2
                and.l   d0,d3
                and.l   d0,d4
                move.l  d2,(a0)+
                move.l  d3,(a1)+
                move.l  d4,(a2)+
                move.l  (a0),d2
                move.l  (a1),d3
                move.l  (a2),d4
                and.l   d1,d2
                and.l   d1,d3
                and.l   d1,d4
                move.l  d2,(a0)+
                move.l  d3,(a1)+
                move.l  d4,(a2)+
                dbf     d7,Effect_ApplyTransitionMask_Loop
                bra.w   Effect_QueueTransitionVdpRegisters
; End of function Effect_ApplyTransitionMask
; ---------------------------------------------------------------------------
Effect_TransitionMaskPatternsA: dc.l    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFF0FFF  ; was: dword_2740E
                dc.l    $F0F0F0F, $F0F0F0F, $F0F0F0F, $F000F
                dc.l    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFF0FFF0
                dc.l    $F0F0F0F0, $F0F0F0F0, $F0F0F0F0, $F000F000

; Applies masked scroll pattern using time-based lookup from Effect_TransitionMaskPatternsB table, creates layered effect masks
Orphaned_ScrollMaskPattern1:
                lea     Effect_TransitionMaskPatternsB(pc),a1  ; was: sub_2744E
                nop
                move.w  (TransitionProgress).w,d2
                asr.w   #2,d2
                andi.w  #$1C,d2
                move.l  (a1,d2.w),d6
                move.l  $20(a1,d2.w),d7
                moveq   #0,d0
                move.l  #$EEEE0000,d1
                move.l  #$EEEEEEEE,d2
                move.l  d0,d3
                move.l  d1,d4
                move.l  d2,d5
                and.l   d6,d0
                and.l   d6,d1
                and.l   d6,d2
                and.l   d7,d3
                and.l   d7,d4
                and.l   d7,d5
                bra.w   Effect_BuildTransitionPattern_Write
; End of function Orphaned_ScrollMaskPattern1
; ---------------------------------------------------------------------------
Effect_TransitionMaskPatternsB: dc.l    $FFFFFFFF, $FFFFFFF, $FFF0FFF, $F0F0FFF  ; was: dword_2748A
                dc.l    $F0F0F0F, $F0F0F, $F000F, $F
                dc.l    $FFFFFFFF, $FFFFFFF0, $FFF0FFF0, $FFF0F0F0
                dc.l    $F0F0F0F0, $F0F0F000, $F000F000, $F0000000

; Builds the denser transition output used by buffer mode four
TransitionEffect_UpdateMode4Buffers:                    ; was: sub_274CA
                movea.w #(TransitionWorkingBuffer-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a1
                moveq   #3,d7
                bsr.w   Effect_Copy32ByteBlocks
                movea.w #(TransitionEdgeCenter4-M68K_RAM),a0
                movea.w #(TransitionEdgeCenter4-M68K_RAM),a2
                movea.l #Effect_TransitionSineTable,a1
                move.w  #$FF00,d5
                moveq   #$FFFFFFFE,d6
                move.w  #$3E,d7                         ; '>'
                move.w  (TransitionProgress).w,d1
                asl.w   #8,d1
                asl.w   #1,d1
                moveq   #0,d3
                move.w  (TransitionProgress).w,d2
                beq.s   TransitionEffect_UpdateMode4Buffers_BeginEdgeLoop
                move.l  (TransitionEdgeSpan).w,d3
                divu.w  d2,d3
                andi.l  #$FFFF,d3
                asl.l   #1,d3
                asl.l   #8,d3
TransitionEffect_UpdateMode4Buffers_BeginEdgeLoop:      ; was: loc_27510
                moveq   #0,d2
TransitionEffect_UpdateMode4Buffers_EdgeLoop:           ; was: loc_27512
                sub.l   d3,d2
                move.l  d2,d4
                swap    d4
                and.w   d6,d4
                cmp.w   d5,d4
                bpl.s   TransitionEffect_UpdateMode4Buffers_ReadSample
                moveq   #0,d0
                bra.s   TransitionEffect_UpdateMode4Buffers_StoreSample
; ---------------------------------------------------------------------------
TransitionEffect_UpdateMode4Buffers_ReadSample:         ; was: loc_27522
                move.w  (a1,d4.w),d0
                mulu.w  d1,d0
                swap    d0
                andi.w  #$FFFC,d0
TransitionEffect_UpdateMode4Buffers_StoreSample:        ; was: loc_2752E
                move.w  d0,-(a0)
                move.w  d0,(a2)+
                dbf     d7,TransitionEffect_UpdateMode4Buffers_EdgeLoop
                movea.w #(TransitionRasterWork-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a2
                movea.w #(TransitionVScrollBuffer-M68K_RAM),a3
                move.w  (TransitionOriginXY).w,d4
                subi.w  #$80,d4
                move.w  (TransitionOriginXY+2).w,d0
                subi.w  #$180,d0
                asr.w   #1,d0
                neg.w   d0
                andi.w  #$FFFE,d0
                adda.w  d0,a0
                moveq   #4,d1
                move.w  #$FC,d2
                moveq   #$3E,d7                         ; '>'
TransitionEffect_UpdateMode4Buffers_OutputLoop:         ; was: loc_27564
                move.w  (a0)+,d0
                cmpa.w  #$9A02,a0
                bmi.s   TransitionEffect_UpdateMode4Buffers_ClearOutsideRange
                cmpa.w  #$9B00,a0
                bmi.s   TransitionEffect_UpdateMode4Buffers_CheckOffset
TransitionEffect_UpdateMode4Buffers_ClearOutsideRange:  ; was: loc_27572
                moveq   #0,d0
TransitionEffect_UpdateMode4Buffers_CheckOffset:        ; was: loc_27574
                move.w  d4,d5
                sub.w   d0,d5
                move.w  d5,d6
                bmi.s   TransitionEffect_UpdateMode4Buffers_AdjustOffset
                cmpi.w  #8,d5
                bpl.s   TransitionEffect_UpdateMode4Buffers_ClampSample
TransitionEffect_UpdateMode4Buffers_AdjustOffset:       ; was: loc_27582
                asr.w   #1,d5
                add.w   d5,d0
                bpl.s   TransitionEffect_UpdateMode4Buffers_ZeroOffset
TransitionEffect_UpdateMode4Buffers_ClearSample:        ; was: loc_27588
                moveq   #0,d0
TransitionEffect_UpdateMode4Buffers_ZeroOffset:         ; was: loc_2758A
                moveq   #0,d5
                andi.w  #4,d6
                add.w   d6,d5
                bra.s   TransitionEffect_UpdateMode4Buffers_StoreOutput
; ---------------------------------------------------------------------------
TransitionEffect_UpdateMode4Buffers_ClampSample:        ; was: loc_27594
                cmpi.w  #$9E,d0
                bmi.s   TransitionEffect_UpdateMode4Buffers_CheckUpperBound
                move.w  #$9E,d0
TransitionEffect_UpdateMode4Buffers_CheckUpperBound:    ; was: loc_2759E
                cmpi.w  #$140,d5
                bpl.s   TransitionEffect_UpdateMode4Buffers_ClearSample
                move.w  d5,d3
                asr.w   #1,d3
                add.w   d0,d3
                cmpi.w  #$100,d3
                bmi.s   TransitionEffect_UpdateMode4Buffers_StoreOutput
                move.w  #$140,d0
                sub.w   d5,d0
TransitionEffect_UpdateMode4Buffers_StoreOutput:        ; was: loc_275B6
                                        ; TransitionEffect_UpdateMode4Buffers+E4   j
                move.w  d5,(a3)+
                sub.w   d1,d0
                and.w   d2,d0
                move.w  d0,(a2)+
                addq.w  #4,d1
                dbf     d7,TransitionEffect_UpdateMode4Buffers_OutputLoop
                rts
; End of function TransitionEffect_UpdateMode4Buffers
