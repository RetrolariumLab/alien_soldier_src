; Packed-BCD digit and double-height frontend text rendering

; Suppresses leading zeroes, stages both glyph rows, and queues their VRAM copies
Text_QueueTrimmedPackedBCDDigits:                       ; CODE XREF: Continue_RenderCreditCount+18   j  ; was: sub_4386
                                        ; Continue_RenderCountdownDigit+10   p
                movea.w (VDPStagingDataCursor).w,a0
                moveq   #0,d5
                move.l  d0,(DMASourceEncoding).w
                move.w  d7,d2
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_EmitOnes
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanTens
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanHundreds
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanThousands
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanTenThousands
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanHundredThousands
                subq.w  #1,d2
                beq.w   Text_TrimmedBCD_ScanMillions
                move.b  (DMASourceEncoding).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitTenMillions
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanMillions
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitTenMillions:                        ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+40   j  ; was: loc_43CE
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanMillions:                           ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+32   j  ; was: loc_43D6
                                        ; Text_QueueTrimmedPackedBCDDigits+46   j
                move.b  (DMASourceEncoding).w,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitMillions
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitMillions
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanHundredThousands
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitMillions:                           ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+58   j  ; was: loc_43EA
                                        ; Text_QueueTrimmedPackedBCDDigits+5C   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanHundredThousands:                   ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+2C   j  ; was: loc_43F2
                                        ; Text_QueueTrimmedPackedBCDDigits+62   j
                move.b  (DMASourceEncoding+1).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitHundredThousands
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitHundredThousands
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanTenThousands
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitHundredThousands:                   ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+76   j  ; was: loc_4408
                                        ; Text_QueueTrimmedPackedBCDDigits+7A   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanTenThousands:                       ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+26   j  ; was: loc_4410
                                        ; Text_QueueTrimmedPackedBCDDigits+80   j
                move.b  (DMASourceEncoding+1).w,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitTenThousands
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitTenThousands
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanThousands
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitTenThousands:                       ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+92   j  ; was: loc_4424
                                        ; Text_QueueTrimmedPackedBCDDigits+96   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanThousands:                          ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+20   j  ; was: loc_442C
                                        ; Text_QueueTrimmedPackedBCDDigits+9C   j
                move.b  (DMASourceEncoding+2).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitThousands
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitThousands
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanHundreds
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitThousands:                          ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+B0   j  ; was: loc_4442
                                        ; Text_QueueTrimmedPackedBCDDigits+B4   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanHundreds:                           ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+1A   j  ; was: loc_444A
                                        ; Text_QueueTrimmedPackedBCDDigits+BA   j
                move.b  (DMASourceEncoding+2).w,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitHundreds
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitHundreds
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_ScanTens
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitHundreds:                           ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+CC   j  ; was: loc_445E
                                        ; Text_QueueTrimmedPackedBCDDigits+D0   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_ScanTens:                               ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+14   j  ; was: loc_4466
                                        ; Text_QueueTrimmedPackedBCDDigits+D6   j
                move.b  (DMASourceEncoding+3).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                bne.s   Text_TrimmedBCD_EmitTens
                tst.w   d5
                bne.s   Text_TrimmedBCD_EmitTens
                subq.w  #1,d7
                addq.w  #2,d4
                bra.s   Text_TrimmedBCD_EmitOnes
; ---------------------------------------------------------------------------
Text_TrimmedBCD_EmitTens:                               ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+EA   j  ; was: loc_447C
                                        ; Text_QueueTrimmedPackedBCDDigits+EE   j
                moveq   #1,d5
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
Text_TrimmedBCD_EmitOnes:                               ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+E   j  ; was: loc_4484
                                        ; Text_QueueTrimmedPackedBCDDigits+F4   j
                move.b  (DMASourceEncoding+3).w,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                movea.w (VDPStagingDataCursor).w,a0
                movea.w a0,a1
                move.w  d7,d2
                asl.w   #1,d2
                adda.w  d2,a1
                move.w  d7,d2
                subq.w  #1,d2
Text_TrimmedBCD_BuildLowerRow:                          ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+122   j  ; was: loc_44A2
                move.w  (a0)+,d0
                addq.w  #1,d0
                move.w  d0,(a1)+
                dbf     d2,Text_TrimmedBCD_BuildLowerRow
                move.w  d7,d3
                bsr.w   VDPQueue_StagedTileWords
                addi.w  #$80,d4
                move.w  d7,d3
                bra.w   VDPQueue_StagedTileWords
; End of function Text_QueueTrimmedPackedBCDDigits
; Stages every requested packed-BCD digit in both glyph rows; no static caller
Text_QueueFixedPackedBCDDigits:
                movea.w (VDPStagingDataCursor).w,a0     ; was: sub_44BC
                movea.w (VDPStagingDataCursor).w,a1
                move.w  d7,d2
                asl.w   #1,d2
                adda.w  d2,a1
                move.l  d0,(DMASourceEncoding).w
                move.w  d7,d2
                subq.w  #1,d2
                beq.w   Text_FixedBCD_EmitOnes
                subq.w  #1,d2
                beq.w   Text_FixedBCD_EmitTens
                subq.w  #1,d2
                beq.s   Text_FixedBCD_EmitHundreds
                subq.w  #1,d2
                beq.s   Text_FixedBCD_EmitThousands
                subq.w  #1,d2
                beq.s   Text_FixedBCD_EmitTenThousands
                subq.w  #1,d2
                beq.s   Text_FixedBCD_EmitHundredThousands
                subq.w  #1,d2
                beq.s   Text_FixedBCD_EmitMillions
                move.b  (DMASourceEncoding).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitMillions:                             ; CODE XREF: Text_QueueFixedPackedBCDDigits+32   j  ; was: loc_4504
                move.b  (DMASourceEncoding).w,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitHundredThousands:                     ; CODE XREF: Text_QueueFixedPackedBCDDigits+2E   j  ; was: loc_4516
                move.b  (DMASourceEncoding+1).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitTenThousands:                         ; CODE XREF: Text_QueueFixedPackedBCDDigits+2A   j  ; was: loc_452A
                move.b  (DMASourceEncoding+1).w,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitThousands:                            ; CODE XREF: Text_QueueFixedPackedBCDDigits+26   j  ; was: loc_453C
                move.b  (DMASourceEncoding+2).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitHundreds:                             ; CODE XREF: Text_QueueFixedPackedBCDDigits+22   j  ; was: loc_4550
                move.b  (DMASourceEncoding+2).w,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitTens:                                 ; CODE XREF: Text_QueueFixedPackedBCDDigits+1C   j  ; was: loc_4562
                move.b  (DMASourceEncoding+3).w,d2
                asr.b   #4,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
Text_FixedBCD_EmitOnes:                                 ; CODE XREF: Text_QueueFixedPackedBCDDigits+16   j  ; was: loc_4576
                move.b  (DMASourceEncoding+3).w,d2
                andi.w  #$F,d2
                asl.w   #1,d2
                add.w   d1,d2
                move.w  d2,(a0)+
                addq.w  #1,d2
                move.w  d2,(a1)+
                move.w  d7,d3
                bsr.w   VDPQueue_StagedTileWords
                addi.w  #$80,d4
                move.w  d7,d3
; End of function Text_QueueFixedPackedBCDDigits
; Prepends one staged-word VRAM DMA record and advances the staging cursor
VDPQueue_StagedTileWords:                               ; CODE XREF: Text_QueueTrimmedPackedBCDDigits+128   p  ; was: sub_4594
                                        ; Text_QueueTrimmedPackedBCDDigits+132   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                move.w  d4,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009300,-(a1)
                move.b  d3,3(a1)
                move.w  a1,(VDPCommandQueueHead).w
                asl.w   #1,d3
                add.w   d3,(VDPStagingDataCursor).w
                rts
; End of function VDPQueue_StagedTileWords
; Expands a terminated character string into two tile rows and queues both rows
Text_QueueDoubleHeightString:                           ; CODE XREF: Results_RenderScoreSummary+32   p  ; was: sub_45D2
                                        ; Results_RenderScoreSummary+46   p
                movea.w (VDPStagingDataCursor).w,a1
                moveq   #0,d7
Text_DoubleHeight_ReadCharacter:                        ; CODE XREF: Text_QueueDoubleHeightString+18   j  ; was: loc_45D8
                moveq   #0,d2
                move.b  (a0)+,d2
                cmpi.b  #$FF,d2
                beq.s   Text_DoubleHeight_BuildLowerRow
                asl.w   #1,d2
                add.w   d0,d2
                move.w  d2,(a1)+
                addq.w  #1,d7
                bra.s   Text_DoubleHeight_ReadCharacter
; ---------------------------------------------------------------------------
Text_DoubleHeight_BuildLowerRow:                        ; CODE XREF: Text_QueueDoubleHeightString+E   j  ; was: loc_45EC
                move.w  d7,d3
                subq.w  #1,d3
                movea.w (VDPStagingDataCursor).w,a0
Text_DoubleHeight_CopyLowerRow:                         ; CODE XREF: Text_QueueDoubleHeightString+28   j  ; was: loc_45F4
                move.w  (a0)+,d0
                addq.w  #1,d0
                move.w  d0,(a1)+
                dbf     d3,Text_DoubleHeight_CopyLowerRow
                move.w  d7,d3
                bsr.w   VDPQueue_StagedTileWords
                addi.w  #$80,d4
                move.w  d4,d5
                andi.w  #$DFFF,d5
                move.w  d7,d3
                bra.w   VDPQueue_StagedTileWords
; End of function Text_QueueDoubleHeightString
; Queues a double-height string and wraps the lower row at the plane boundary
Text_QueueDoubleHeightStringWrapped:                    ; CODE XREF: RegionRestricted+3E   p  ; was: sub_4614
                                        ; RegionRestricted+52   p
                movea.w (VDPStagingDataCursor).w,a1
                moveq   #0,d7
Text_DoubleHeightWrapped_ReadCharacter:                 ; CODE XREF: Text_QueueDoubleHeightStringWrapped+18   j  ; was: loc_461A
                moveq   #0,d2
                move.b  (a0)+,d2
                cmpi.b  #$FF,d2
                beq.s   Text_DoubleHeightWrapped_BuildLowerRow
                asl.w   #1,d2
                add.w   d0,d2
                move.w  d2,(a1)+
                addq.w  #1,d7
                bra.s   Text_DoubleHeightWrapped_ReadCharacter
; ---------------------------------------------------------------------------
Text_DoubleHeightWrapped_BuildLowerRow:                 ; CODE XREF: Text_QueueDoubleHeightStringWrapped+E   j  ; was: loc_462E
                move.w  d7,d3
                subq.w  #1,d3
                movea.w (VDPStagingDataCursor).w,a0
Text_DoubleHeightWrapped_CopyLowerRow:                  ; CODE XREF: Text_QueueDoubleHeightStringWrapped+28   j  ; was: loc_4636
                move.w  (a0)+,d0
                addq.w  #1,d0
                move.w  d0,(a1)+
                dbf     d3,Text_DoubleHeightWrapped_CopyLowerRow
                move.w  d7,d3
                bsr.w   VDPQueue_StagedTileWords
                addi.w  #$80,d4
                move.w  d4,d5
                andi.w  #$DFFF,d5
                cmpi.w  #$5000,d5
                bmi.s   Text_DoubleHeightWrapped_QueueLowerRow
                subi.w  #$1000,d4
Text_DoubleHeightWrapped_QueueLowerRow:                 ; CODE XREF: Text_QueueDoubleHeightStringWrapped+40   j  ; was: loc_465A
                move.w  d7,d3
                bra.w   VDPQueue_StagedTileWords
; End of function Text_QueueDoubleHeightStringWrapped
; ---------------------------------------------------------------------------
; Terminated frontend strings; character codes index pairs of font tiles
Text_BlankStageReadyStatus: dc.b    0, 0, 0, 0, 0, 0, 0, 0  ; was: byte_4660
                                        ; DATA XREF: StageReady_Update+22   o
                dc.b    0, 0, 0, 0, 0, 0, 0, 0
                dc.b    $FF
Text_SpacedReady:   dc.b    $1C, 0, $F, 0, $B, 0, $E, 0, $23, $FF  ; was: byte_4671
                                        ; DATA XREF: StageReady_Update:StageReady_Update_RenderReady   o
Text_SixteenDigitPlaceholder:
                dc.b    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
Text_FourDigitPlaceholder:  dc.b    1, 1                ; DATA XREF: Results_RenderScoreSummary+9C   o  ; was: byte_4687
                                        ; Results_RenderScoreSummary+C4   o
Text_TwoDigitPlaceholder:   dc.b    1, 1, $FF           ; DATA XREF: Continue_RenderCreditHeader+14   o  ; was: byte_4689
                                        ; Continue_RenderStageAndDifficulty+32   o
Text_EightDigitPointsPlaceholder:   dc.b    1, 1, 1, 1, 1, 1, 1, 1, $1A, $1E, $1D, $FF  ; was: byte_468C
                                        ; DATA XREF: Results_RenderScoreSummary+4C   o
                                        ; Results_RenderScoreSummary+74   o
Text_GameStart: dc.b    $11, $B, $17, $F, 0, $1D, $1E, $B  ; was: byte_4698
                                        ; DATA XREF: TitleScreen_QueueGameStart   o
                dc.b    $1C, $1E, $FF
Text_Options:   dc.b    $19, $1A, $1E, $13, $19, $18, $1D, $FF  ; was: byte_46A3
                                        ; DATA XREF: TitleScreen_QueueOptions   o
                                        ; UI_InitOptionsScreen+BE   o
Text_Password:  dc.b    $1A, $B, $1D, $1D, $21, $19, $1C, $E, $FF  ; was: byte_46AB
                                        ; DATA XREF: TitleScreen_QueuePassword   o
Text_VisualSpeedSoundShock: dc.b    $20, $13, $1D, $1F, $B, $16, $1D, $12  ; was: byte_46B4
                                        ; DATA XREF: TitleScreen_Initialize+CE   o
                dc.b    $19, $D, $15, $29, 0, $1D, $1A, $F
                dc.b    $F, $E, $1D, $12, $19, $D, $15, $29
                dc.b    0, $1D, $19, $1F, $18, $E, $1D, $12
                dc.b    $19, $D, $15, $29, $FF
Text_HeartOnFire:   dc.b    $18, $19, $21, 0, $13, $1D, 0, $1E  ; was: byte_46D9
                                        ; DATA XREF: TitleScreen_Initialize+E2   o
                dc.b    $13, $17, $F, 0, $1E, $19, 0, $1E
                dc.b    $12, $F, 0, 7, 9, 1, 1, 1
                dc.b    0, $12, $F, $B, $1C, $1E, 0, $19
                dc.b    $18, 0, $10, $13, $1C, $F, $29, $FF
Text_ForMegaDriversCustom:  dc.b    $10, $19, $1C, 0, $17, $F, $11, $B  ; was: byte_4701
                                        ; DATA XREF: TitleScreen_Initialize+F6   o
                dc.b    $E, $1C, $13, $20, $F, $1C, $1D, 0
                dc.b    $D, $1F, $1D, $1E, $19, $17, $FF
Text_SegaCopyright1995: dc.b    0, $2F, $1D, $F, $11, $B, 0, $F  ; was: byte_4718
                                        ; DATA XREF: TitleScreen_Initialize+10A   o
                dc.b    $18, $1E, $F, $1C, $1A, $1C, $13, $1D
                dc.b    $F, $1D, $26, $16, $1E, $E, $25, 2
                dc.b    $A, $A, 6, $FF
Text_Level:     dc.b    $16, $F, $20, $F, $16, $FF      ; was: byte_4734
                                        ; DATA XREF: UI_InitOptionsScreen+D2   o
Text_MessageSwitch: dc.b    $17, $F
                dc.b    $1D, $1D, $B, $11, $F, 0, $1D, $21
                dc.b    $13, $1E, $D, $12, $FF
Text_BGMSwitch: dc.b    $C, $11, $17, 0, $1D, $21, $13, $1E  ; was: byte_4749
                                        ; DATA XREF: UI_InitOptionsScreen+E6   o
                dc.b    $D, $12, $FF
Text_SFXSwitch: dc.b    $1D, $26, $F, 0, $1D, $21, $13, $1E  ; was: byte_4754
                                        ; DATA XREF: UI_InitOptionsScreen+FA   o
                dc.b    $D, $12, $FF
Text_BGMTest:   dc.b    $C, $11, $17, 0, $1E, $F, $1D, $1E  ; was: byte_475F
                                        ; DATA XREF: UI_InitOptionsScreen+10E   o
                dc.b    $FF
Text_SFXTest:   dc.b    $1D, $26, $F, 0, $1E, $F, $1D, $1E  ; was: byte_4768
                                        ; DATA XREF: UI_InitOptionsScreen+122   o
                dc.b    $FF
Text_VoiceTest: dc.b    $20, $19, $13, $D, $F, 0, $1E, $F  ; was: byte_4771
                                        ; DATA XREF: UI_InitOptionsScreen+136   o
                dc.b    $1D, $1E, $FF
Text_PressStartToExit:  dc.b    $1A, $1C, $F, $1D, $1D, 0, $1D, $1E, $B, $1C  ; was: byte_477C
                                        ; DATA XREF: UI_InitOptionsScreen+14A   o
                                        ; PasswordMenu_Initialize+F6   o
                dc.b    $1E, 0, $1E, $19, 0, $F, $22, $13, $1E, $FF
Text_Continue:  dc.b    $D, $19, $18, $1E, $13, $18, $1F, $F, $FF  ; was: byte_4790
                                        ; DATA XREF: Continue_RenderPrompt+4   o
Text_GameEnd:   dc.b    $11, $B, $17, $F, $F, $18, $E, $FF
Text_StageDash: dc.b    $1D, $1E, $B, $11, $F, $2E, $FF  ; was: byte_47A1
                                        ; DATA XREF: Continue_RenderStageAndDifficulty   o
Text_PasswordDash:  dc.b    $1A, $B, $1D, $1D, $21, $19, $1C, $E  ; was: byte_47A8
                                        ; DATA XREF: Continue_RenderPassword   o
                dc.b    $2E, $FF
Text_CreditDash:    dc.b    $D, $1C, $F, $E, $13, $1E, $2E, $FF  ; was: byte_47B2
                                        ; DATA XREF: Continue_RenderCreditHeader   o
Text_LevelDash: dc.b    $16, $F, $20, $F, $16, $2E, $FF  ; was: byte_47BA
                                        ; DATA XREF: Continue_RenderStageAndDifficulty+46   o
Text_Easy:      dc.b    $F, $B, $1D, $23, $FF           ; was: byte_47C1
                                        ; DATA XREF: Continue_RenderStageAndDifficulty+5A   o
Text_Hard:      dc.b    $12, $B, $1C, $E, $FF           ; was: byte_47C6
                                        ; DATA XREF: Continue_RenderStageAndDifficulty+66   o
Text_FiveSpecialGlyphs:     dc.b    $C9, $CA, $CB, $CC, $CD, $FF
Text_YouLostThreeChances:   dc.b    $23, $19, $1F, 0, $16, $19, $1D, $1E  ; was: byte_47D1
                                        ; DATA XREF: RetryPrompt_Initialize+7A   o
                dc.b    0, 4, $D, $12, $B, $18, $D, $F
                dc.b    $1D, $25, $25, $25, $FF
Text_TryAgain:  dc.b    $1E, $1C, $23, 0, $B, $11, $B, $13  ; was: byte_47E6
                                        ; DATA XREF: RetryPrompt_Initialize+8E   o
                dc.b    $18, $29, $29, $FF
Text_PressStart:    dc.b    $1A, $1C, $F, $1D, $1D, 0, $1D, $1E  ; was: byte_47F2
                                        ; DATA XREF: RetryPrompt_Initialize+A2   o
                                        ; sub_1E430   o
                dc.b    $B, $1C, $1E, $FF
Text_Results:   dc.b    $1C, $F, $1D, $1F, $16, $1E, $1D, $FF  ; was: byte_47FE
                                        ; DATA XREF: Results_RenderScoreSummary+24   o
Text_HighScore: dc.b    $12, $13, $11, $12, 0, $1D, $D, $19  ; was: byte_4806
                                        ; DATA XREF: Results_RenderScoreSummary+38   o
                dc.b    $1C, $F, $FF
Text_Score:     dc.b    $1D, $D, $19, $1C, $F, $FF      ; was: byte_4811
                                        ; DATA XREF: Results_RenderScoreSummary+60   o
Text_ContinueLabel:     dc.b    $D, $19, $18, $1E, $13, $18, $1F, $F, $FF
Text_DestroyedEnemies:  dc.b    $E, $F, $1D, $1E, $1C, $19, $23, $F  ; was: byte_4820
                                        ; DATA XREF: Results_RenderScoreSummary+88   o
                dc.b    $E, 0, $F, $18, $F, $17, $13, $F
                dc.b    $1D, $FF
Text_PlayerDamage:  dc.b    $1A, $16, $B, $23, $F, $1C, 0, $E  ; was: byte_4832
                                        ; DATA XREF: Results_RenderScoreSummary+B0   o
                dc.b    $B, $17, $B, $11, $F, $FF

; Clears scroll planes A/B and initializes display state
