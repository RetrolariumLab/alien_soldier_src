; Updates the animated dithered background of the weapon-setup screen
WeaponSetup_UpdateBackgroundEffect:                     ; was: sub_1F82E
                cmpi.w  #$A,(SetupTransitionIndex).w
                bpl.s   WeaponSetup_IncreaseBackgroundPhase
                subi.l  #$18000,(WeaponSetupBgPhase).w
                cmpi.l  #$B00000,(WeaponSetupBgPhase).w
                bpl.s   WeaponSetup_RenderBackgroundPhase
                move.l  #$1500000,(WeaponSetupBgPhase).w
                bra.s   WeaponSetup_RenderBackgroundPhase
; ---------------------------------------------------------------------------
WeaponSetup_IncreaseBackgroundPhase:                    ; was: loc_1F852
                addi.l  #$18000,(WeaponSetupBgPhase).w
                cmpi.l  #$1500000,(WeaponSetupBgPhase).w
                bmi.s   WeaponSetup_RenderBackgroundPhase
                move.l  #$B00000,(WeaponSetupBgPhase).w
WeaponSetup_RenderBackgroundPhase:                      ; was: loc_1F86C
                                        ; WeaponSetup_UpdateBackgroundEffect+22   j
                move.w  (WeaponSetupBgPhase).w,d0
                asr.w   #3,d0
                subi.w  #$16,d0
                andi.w  #$1E,d0
; At wrap phase $01500000, index $14 reaches the following table/code word
                move.w  WeaponSetup_BackgroundPaletteColor1Cycle(pc,d0.w),(PaletteActiveColor62).w
                move.w  WeaponSetup_BackgroundPaletteColor2Cycle(pc,d0.w),(PaletteActiveColor63).w
                movea.w #(WeaponSetupRasterLines-M68K_RAM),a0
                moveq   #1,d0
                move.w  #$60,d7                         ; '`'
WeaponSetup_InitializeLineOffsetLoop:                   ; was: loc_1F890
                move.w  d0,(a0)+
                subq.w  #2,d0
                dbf     d7,WeaponSetup_InitializeLineOffsetLoop
                movea.w #(WeaponSetupOffsetCenter-M68K_RAM),a0
                move.l  (WeaponSetupBgPhase).w,d0
                subi.l  #Z80_RAM,d0
                move.l  d0,d1
                move.l  d0,d2
                lsr.l   #1,d2
                sub.l   d2,d0
WeaponSetup_BuildFirstOffsetTableLoop:                  ; was: loc_1F8AE
                swap    d0
                move.w  d0,d3
                addq.w  #6,d3
                neg.w   d3
                move.w  d0,d2
                andi.w  #$FFFE,d2
                move.w  d3,(a0,d2.w)
                move.w  d0,d3
                addq.w  #4,d3
                move.w  d0,d2
                addq.w  #2,d2
                neg.w   d2
                andi.w  #$FFFE,d2
                move.w  d3,(a0,d2.w)
                swap    d0
                add.l   d1,d0
                cmpi.l  #$600000,d0
                bmi.s   WeaponSetup_BuildFirstOffsetTableLoop
                move.l  (WeaponSetupBgPhase).w,d0
                move.l  d0,d1
                move.l  d0,d2
                lsr.l   #1,d2
                sub.l   d2,d0
WeaponSetup_BuildSecondOffsetTableLoop:                 ; was: loc_1F8EA
                swap    d0
                move.w  d0,d3
                addq.w  #2,d3
                neg.w   d3
                move.w  d0,d2
                andi.w  #$FFFE,d2
                move.w  d3,(a0,d2.w)
                move.w  d0,d3
                subq.w  #8,d3
                move.w  d0,d2
                addq.w  #2,d2
                neg.w   d2
                andi.w  #$FFFE,d2
                move.w  d3,(a0,d2.w)
                swap    d0
                add.l   d1,d0
                cmpi.l  #$600000,d0
                bmi.s   WeaponSetup_BuildSecondOffsetTableLoop
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.l  #$EEEEEEEE,d0
                moveq   #$FFFFFFFF,d1
                moveq   #0,d2
                moveq   #$13,d7
WeaponSetup_SeedBackgroundTileRows:                     ; was: loc_1F92A
                move.l  d0,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d1,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                dbf     d7,WeaponSetup_SeedBackgroundTileRows
                move.l  (WeaponSetupBgPhase).w,d0
                subi.l  #Z80_RAM,d0
                move.l  d0,d1
                move.l  d0,d2
                lsr.l   #1,d2
                sub.l   d2,d0
WeaponSetup_DrawFirstDitherBandLoop:                    ; was: loc_1F950
                swap    d0
                btst    #0,d0
                beq.s   WeaponSetup_SelectFirstEvenDitherPattern
                move.w  #$F,d1
                move.w  #$F,d2
                bra.s   WeaponSetup_DrawFirstDitherBandColumn
; ---------------------------------------------------------------------------
WeaponSetup_SelectFirstEvenDitherPattern:               ; was: loc_1F962
                move.w  #$F0,d1
                move.w  #$FF,d2
WeaponSetup_DrawFirstDitherBandColumn:                  ; was: loc_1F96A
                bsr.s   WeaponSetup_WriteDitherColumn
                swap    d0
; MOVE.W above leaves D1's phase-derived high word intact; ADD.L uses all 32 bits
                add.l   d1,d0
                cmpi.l  #Z80_RAM,d0
                bmi.s   WeaponSetup_DrawFirstDitherBandLoop
                move.l  (WeaponSetupBgPhase).w,d0
                move.l  d0,d1
                move.l  d0,d2
                lsr.l   #1,d2
                sub.l   d2,d0
WeaponSetup_DrawSecondDitherBandLoop:                   ; was: loc_1F984
                swap    d0
                btst    #0,d0
                beq.s   WeaponSetup_SelectSecondEvenDitherPattern
                move.w  #$E,d1
                move.w  #$FE,d2
                bra.s   WeaponSetup_DrawSecondDitherBandColumn
; ---------------------------------------------------------------------------
WeaponSetup_SelectSecondEvenDitherPattern:              ; was: loc_1F996
                move.w  #$E0,d1
                move.w  #$EF,d2
WeaponSetup_DrawSecondDitherBandColumn:                 ; was: loc_1F99E
                bsr.s   WeaponSetup_WriteDitherColumn
                swap    d0
; As in the first band, the word-sized pattern load does not clear D1's high word
                add.l   d1,d0
                cmpi.l  #Z80_RAM,d0
                bmi.s   WeaponSetup_DrawSecondDitherBandLoop
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.w  #$7000,d0
                move.w  #$8F02,d3
                move.l  #$94019340,d4
                jmp     VDP_QueueCommand_Build
; End of function WeaponSetup_UpdateBackgroundEffect
; Writes a seven-row dither column into the background tile buffer
WeaponSetup_WriteDitherColumn:                          ; was: sub_1F9C4
                                        ; WeaponSetup_UpdateBackgroundEffect:WeaponSetup_DrawSecondDitherBandColumn   p
                move.w  d0,d3
                move.w  d0,d4
                asr.w   #1,d3
                andi.w  #3,d3
                andi.w  #$FFF8,d4
                asl.w   #2,d4
                add.w   d3,d4
                addi.w  #-$6C00,d4
                movea.w d4,a0
                move.b  d1,4(a0)
                move.b  d1,8(a0)
                move.b  d1,$C(a0)
                move.b  d2,$10(a0)
                move.b  d1,$14(a0)
                move.b  d1,$18(a0)
                move.b  d1,$1C(a0)
                rts
; End of function WeaponSetup_WriteDitherColumn
; ---------------------------------------------------------------------------
WeaponSetup_HeadingText:    dc.b    0, $1D, $F, $1E, $1F, $1A, 0, $23, $19, $1F, $1C, 0, $21, $F, $B, $1A  ; was: byte_1F9FA
                dc.b    $19, $18, $1D, 0, $FF
WeaponSetup_BusterForceText:            dc.b    $C, $1F, $1D, $1E, $F, $1C, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA0F
WeaponSetup_RangerForceText:            dc.b    $1C, $B, $18, $11, $F, $1C, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA1C
WeaponSetup_FlameForceText:             dc.b    $10, $16, $B, $17, $F, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA29
WeaponSetup_HomingForceText:            dc.b    $12, $19, $17, $13, $18, $11, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA35
WeaponSetup_SwordForceText:             dc.b    $1D, $21, $19, $1C, $E, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA42
WeaponSetup_LancerForceText:            dc.b    $16, $B, $18, $D, $F, $1C, 0, $10, $19, $1C, $D, $F, $FF  ; was: byte_1FA4E
WeaponSetup_ShootingModeText:           dc.b    $1D, $12, $19, $19, $1E, $13, $18, $11, 0, $17, $19, $E, $F, $FF  ; was: byte_1FA5B
WeaponSetup_MovingModeText:             dc.b    $17, $19, $20, $13, $18, $11, $FF  ; was: byte_1FA69
WeaponSetup_FixedModeText:              dc.b    $10, $13, $22, $FF  ; was: byte_1FA70
WeaponSetup_StatusWindowText:           dc.b    $1D, $1E, $B, $1E, $1F, $1D, 0, $21, $13, $18, $E, $19, $21, $FF  ; was: byte_1FA74
WeaponSetup_ControlType01Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 0, $FF  ; was: byte_1FA82
WeaponSetup_ControlType02Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 0, $FF  ; was: byte_1FA8A
WeaponSetup_ControlType03Text:          dc.b    $1E, $23, $1A, $F, $2E, 4, 0, $FF  ; was: byte_1FA92
WeaponSetup_ControlType04Text:          dc.b    $1E, $23, $1A, $F, $2E, 5, 0, $FF  ; was: byte_1FA9A
WeaponSetup_ControlType05Text:          dc.b    $1E, $23, $1A, $F, $2E, 6, 0, $FF  ; was: byte_1FAA2
WeaponSetup_ControlType06Text:          dc.b    $1E, $23, $1A, $F, $2E, 7, 0, $FF  ; was: byte_1FAAA
WeaponSetup_ControlType07Text:          dc.b    $1E, $23, $1A, $F, $2E, 8, 0, $FF  ; was: byte_1FAB2
WeaponSetup_ControlType08Text:          dc.b    $1E, $23, $1A, $F, $2E, 9, 0, $FF  ; was: byte_1FABA
WeaponSetup_ControlType09Text:          dc.b    $1E, $23, $1A, $F, $2E, $A, 0, $FF  ; was: byte_1FAC2
WeaponSetup_ControlType10Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 1, $FF  ; was: byte_1FACA
WeaponSetup_ControlType11Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 2, $FF  ; was: byte_1FAD2
WeaponSetup_ControlType12Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 3, $FF  ; was: byte_1FADA
WeaponSetup_ControlType13Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 4, $FF  ; was: byte_1FAE2
WeaponSetup_ControlType14Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 5, $FF  ; was: byte_1FAEA
WeaponSetup_ControlType15Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 6, $FF  ; was: byte_1FAF2
WeaponSetup_ControlType16Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 7, $FF  ; was: byte_1FAFA
WeaponSetup_ControlType17Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 8, $FF  ; was: byte_1FB02
WeaponSetup_ControlType18Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, 9, $FF  ; was: byte_1FB0A
WeaponSetup_ControlType19Text:          dc.b    $1E, $23, $1A, $F, $2E, 2, $A, $FF  ; was: byte_1FB12
WeaponSetup_ControlType20Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 1, $FF  ; was: byte_1FB1A
WeaponSetup_ControlType21Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 2, $FF  ; was: byte_1FB22
WeaponSetup_ControlType22Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 3, $FF  ; was: byte_1FB2A
WeaponSetup_ControlType23Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 4, $FF  ; was: byte_1FB32
WeaponSetup_ControlType24Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 5, $FF  ; was: byte_1FB3A
WeaponSetup_ControlType25Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 6, $FF  ; was: byte_1FB42
WeaponSetup_ControlType26Text:          dc.b    $1E, $23, $1A, $F, $2E, 3, 7, $FF  ; was: byte_1FB4A
WeaponSetup_ExitText:                   dc.b    $F, $22, $13, $1E, $FF  ; was: byte_1FB52
WeaponSetup_ControlTestText:            dc.b    $D, $19, $18, $1E, $1C, $19, $16, 0, $1E, $F, $1D, $1E, $FF  ; was: byte_1FB57
WeaponSetup_WeaponSelectControlText:    dc.b    $21, $F, $B, $1A, $19, $18, 0, $1D, $F, $16, $F, $D, $1E, 0, $2E, 0  ; was: byte_1FB64
                dc.b    $E0, $E1, $FF
WeaponSetup_ShotControlText:                dc.b    $1D, $12, $19, $1E, 0, $2E, 0, $E2, $E3, $FF  ; was: byte_1FB77
WeaponSetup_JumpControlText:                dc.b    $14, $1F, $17, $1A, 0, $2E, 0, $E4, $E5, $FF  ; was: byte_1FB81
WeaponSetup_ShootingModeChangeControlText:  dc.b    $1D, $12, $19, $19, $1E, 0, $17, $19, $E, $F, 0, $D, $12, $B, $18, $11  ; was: byte_1FB8B
                dc.b    $F, 0, $2E, 0, $E6, $E7, 0, $E8, 0, $E0, $E1, $FF
WeaponSetup_ZeroTeleportControlText:    dc.b    $24, $F, $1C, $19, 0, $1E, $F, $16, $F, $1A, $19, $1C, $1E, 0, $2E, 0  ; was: byte_1FBA7
                dc.b    $E6, $E7, 0, $E8, 0, $E4, $E5, $FF
WeaponSetup_CounterForceControlText:    dc.b    $D, $19, $1F, $18, $1E, $F, $1C, 0, $10, $19, $1C, $D, $F, 0, $2E, 0  ; was: byte_1FBBF
                dc.b    $E2, $E3, 0, $E8, 0, $E2, $E3, $FF
WeaponSetup_HoveringControlText:    dc.b    $12, $19, $20, $F, $1C, $13, $18, $11, 0, $2E, 0, $14, $1F, $17, $1A, 0  ; was: byte_1FBD7
                dc.b    $E8, 0, $E4, $E5, $FF
