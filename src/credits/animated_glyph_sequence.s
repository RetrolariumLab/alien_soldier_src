CreditsGlyphSequence_Dispatch:                          ; was: sub_21A5C
                                        ; sub_20C88   p
                move.w  (SharedSequenceState).l,d0
                lea     CreditsGlyphSequence_StateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function CreditsGlyphSequence_Dispatch
; ---------------------------------------------------------------------------
CreditsGlyphSequence_StateOffsets:  dc.w    CreditsGlyphSequence_Initialize-*  ; was: off_21A6A
                dc.w    CreditsGlyphSequence_SpawnNextRecord-*
                dc.w    CreditsGlyphSequence_WaitForGlyphs-*
                dc.w    CreditsGlyphSequence_Delay-*
                dc.w    CreditsGlyphSequence_Idle-*

; Initializes the animated credits-glyph record sequence
CreditsGlyphSequence_Initialize:                        ; was: sub_21A74
                move.w  #$222,(PaletteActiveColor01).w
                move.w  #$EEE,(PaletteActiveColor02).w
                move.l  #CreditsGlyphSequenceData,(SharedSequenceCursor).l
                addq.w  #2,(SharedSequenceState).l
; Parses and spawns the next two-row credits-glyph record
CreditsGlyphSequence_SpawnNextRecord:                   ; was: loc_21A90
                lea     (QuaternaryEntityType).w,a0
                movea.l (SharedSequenceCursor).l,a1
                moveq   #0,d0
                move.b  (a1)+,d0
                bmi.w   CreditsGlyphSequence_Finish
                add.w   d0,d0
                move.w  d0,(SharedSequenceTimer).l
                move.b  (a1)+,d0
                beq.w   CreditsGlyphSequence_ReadLowerRow
                move.w  d0,d1
                subq.w  #1,d1
                add.w   d1,d1
                add.w   d1,d1
                move.w  #$120,d3
                sub.w   d1,d3
                move.w  #$E4,d4
                move.w  d0,d1
                subq.w  #1,d1
                muls.w  #$10,d1
                move.w  #$180,d5
                sub.w   d1,d5
                move.w  d0,d7
                subq.w  #1,d7
CreditsGlyphSequence_SpawnUpperRowLoop:                 ; was: loc_21AD4
                move.b  (a1)+,d0
                cmpi.b  #0,d0
                beq.s   CreditsGlyphSequence_AdvanceUpperSlot
                bsr.w   CreditsGlyph_InitializeObject
                add.w   d0,d0
                ori.w   #$8000,d0
                move.w  d0,$E(a0)
                move.w  d3,$10(a0)
                move.w  d4,$14(a0)
                move.w  d5,$4C(a0)
                move.w  (SharedSequenceTimer).l,$46(a0)
CreditsGlyphSequence_AdvanceUpperSlot:                  ; was: loc_21AFE
                addq.w  #8,d3
                addi.w  #$20,d5                         ; ' '
                lea     $60(a0),a0
                dbf     d7,CreditsGlyphSequence_SpawnUpperRowLoop
CreditsGlyphSequence_ReadLowerRow:                      ; was: loc_21B0C
                moveq   #0,d0
                move.b  (a1)+,d0
                add.w   d0,d0
                move.w  d0,(SharedSequenceTimer).l
                move.b  (a1)+,d0
                beq.w   CreditsGlyphSequence_CommitRecord
                move.w  d0,d1
                subq.w  #1,d1
                add.w   d1,d1
                add.w   d1,d1
                move.w  #$120,d3
                sub.w   d1,d3
                move.w  #$FC,d4
                move.w  d0,d1
                subq.w  #1,d1
                muls.w  #$10,d1
                addi.w  #$80,d1
                move.w  d1,d5
                move.w  d0,d7
                subq.w  #1,d7
CreditsGlyphSequence_SpawnLowerRowLoop:                 ; was: loc_21B42
                move.b  (a1)+,d0
                cmpi.b  #0,d0
                beq.s   CreditsGlyphSequence_AdvanceLowerSlot
                bsr.w   CreditsGlyph_InitializeObject
                add.w   d0,d0
                ori.w   #$8000,d0
                move.w  d0,$E(a0)
                move.w  d3,$10(a0)
                move.w  d4,$14(a0)
                move.w  d5,$4C(a0)
                move.w  (SharedSequenceTimer).l,$46(a0)
CreditsGlyphSequence_AdvanceLowerSlot:                  ; was: loc_21B6C
                addq.w  #8,d3
                subi.w  #$20,d5                         ; ' '
                lea     $60(a0),a0
                dbf     d7,CreditsGlyphSequence_SpawnLowerRowLoop
CreditsGlyphSequence_CommitRecord:                      ; was: loc_21B7A
                move.l  a1,(SharedSequenceCursor).l
                addq.w  #2,(SharedSequenceState).l
                rts
; ---------------------------------------------------------------------------
CreditsGlyphSequence_Finish:                            ; was: loc_21B88
                move.w  #8,(SharedSequenceState).l
                rts
; End of function CreditsGlyphSequence_Initialize
; Wait for menu animation to complete
CreditsGlyphSequence_WaitForGlyphs:                     ; was: sub_21B92
                lea     (QuaternaryEntityType).w,a0
                cmpi.w  #$464,(a0)
                beq.s   CreditsGlyphSequence_WaitReturn
                move.w  #$10,(SharedSequenceTimer).l
                addq.w  #2,(SharedSequenceState).l
CreditsGlyphSequence_WaitReturn:                        ; was: locret_21BAA
                rts
; End of function CreditsGlyphSequence_WaitForGlyphs
; Delay timer for menu state transitions
CreditsGlyphSequence_Delay:                             ; was: sub_21BAC
                subq.w  #1,(SharedSequenceTimer).l
                bpl.s   CreditsGlyphSequence_DelayReturn
                move.w  #2,(SharedSequenceState).l
CreditsGlyphSequence_DelayReturn:                       ; was: locret_21BBC
                rts
; End of function CreditsGlyphSequence_Delay
CreditsGlyphSequence_Idle:                              ; was: nullsub_55
                rts
; End of function CreditsGlyphSequence_Idle
; ---------------------------------------------------------------------------
CreditsGlyphSequenceData:   binclude "data/credits/animated_glyph_sequence.bin"  ; was: word_21BC0
CreditsGlyphSequenceData_End:                           ; was: word_21BC0_End

; Initializes one animated credits-glyph object
CreditsGlyph_InitializeObject:                          ; was: sub_21F2A
                                        ; CreditsGlyphSequence_SpawnNextRecord+D6   p
                move.w  #$464,(a0)
                move.w  #$4000,2(a0)
                clr.b   $20(a0)
                move.l  #CreditsGlyph_SpriteData,8(a0)
                clr.l   $18(a0)
                clr.l   $1C(a0)
                rts
; End of function CreditsGlyph_InitializeObject
; ---------------------------------------------------------------------------
CreditsGlyph_SpriteData:    dc.b    $83, 0, 1, 0, $F8, $FC  ; was: byte_21F4A

; Dispatches the six animated credits-glyph states
CreditsGlyph_Dispatch:                                  ; was: sub_21F50
                move.w  4(a5),d0
                lea     CreditsGlyph_StateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function CreditsGlyph_Dispatch
; ---------------------------------------------------------------------------
CreditsGlyph_StateOffsets:  dc.w    CreditsGlyph_InitializeMotion-*  ; was: off_21F5C
                dc.w    CreditsGlyph_ExpandOrbit-*
                dc.w    CreditsGlyph_ContractOrbit-*
                dc.w    CreditsGlyph_CollapseOrbitAndSetHold-*
                dc.w    CreditsGlyph_WaitAndStartFall-*
                dc.w    CreditsGlyph_ApplyUpwardAcceleration-*

; Initializes the glyph's fixed-point center, direction, and orbit phase
CreditsGlyph_InitializeMotion:                          ; was: sub_21F68
                addq.w  #2,4(a5)
                move.l  $10(a5),$50(a5)
                move.l  $14(a5),$54(a5)
                move.w  #8,$4A(a5)
                move.w  $4C(a5),d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a4
                move.w  Math_QuarterSineTable-Math_SineTable(a4,d0.w),d1
                move.w  (a4,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #3,d0
                asl.l   #3,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                move.w  (VBlankFrameCounter).w,d0
                add.w   d0,$4C(a5)
                andi.w  #$1FE,$4C(a5)
                rts
; End of function CreditsGlyph_InitializeMotion
; Expands the glyph's orbit in eight integration steps per update
CreditsGlyph_ExpandOrbit:                               ; was: sub_21FB4
                addq.w  #1,$48(a5)
                addi.w  #4,$4C(a5)
                addi.w  #2,$4E(a5)
                move.l  $18(a5),d0
                add.l   d0,$50(a5)
                move.l  $1C(a5),d0
                add.l   d0,$54(a5)
                subq.w  #1,$4A(a5)
                bne.s   CreditsGlyph_ExpandOrbit
                cmpi.w  #$5C,$48(a5)                    ; '\'
                bcc.s   CreditsGlyph_BeginOrbitReturn
                move.w  #8,$4A(a5)
                rts
; ---------------------------------------------------------------------------
CreditsGlyph_BeginOrbitReturn:                          ; was: loc_21FEA
                bsr.w   CreditsGlyph_ProjectOrbitPosition
                neg.l   $18(a5)
                neg.l   $1C(a5)
                bset    #7,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function CreditsGlyph_ExpandOrbit
; Projects the current angle and radius around the moving fixed-point center
CreditsGlyph_ProjectOrbitPosition:                      ; was: sub_22002
                                        ; CreditsGlyph_ContractOrbit+16   p
                move.w  $4C(a5),d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a4
                move.w  Math_QuarterSineTable-Math_SineTable(a4,d0.w),d1
                move.w  (a4,d0.w),d0
                muls.w  $4E(a5),d0
                muls.w  $4E(a5),d1
                asr.l   #1,d1
                add.l   $50(a5),d0
                add.l   $54(a5),d1
                move.l  d0,$10(a5)
                move.l  d1,$14(a5)
                rts
; End of function CreditsGlyph_ProjectOrbitPosition
; Retraces the orbit with reversed center velocity until its phase reaches zero
CreditsGlyph_ContractOrbit:                             ; was: sub_22034
                subi.w  #4,$4C(a5)
                move.l  $18(a5),d0
                add.l   d0,$50(a5)
                move.l  $1C(a5),d0
                add.l   d0,$54(a5)
                bsr.w   CreditsGlyph_ProjectOrbitPosition
                subq.w  #1,$48(a5)
                bne.s   CreditsGlyph_ContractOrbitReturn
                andi.w  #$FFFE,$4E(a5)
                addq.w  #2,4(a5)
CreditsGlyph_ContractOrbitReturn:                       ; was: locret_2205E
                rts
; End of function CreditsGlyph_ContractOrbit
; Unreferenced helper that maps the first glyph's phase to a gray palette ramp
UnreferencedCreditsGlyph_UpdatePaletteRamp:             ; was: sub_22060
                cmpa.w  #$C740,a5
                bne.s   UnreferencedCreditsGlyph_UpdatePaletteRampReturn
                move.w  $48(a5),d0
                lsr.w   #4,d0
                add.w   d0,d0
                move.w  CreditsGlyph_PaletteRamp(pc,d0.w),(PaletteActiveColor01).w
UnreferencedCreditsGlyph_UpdatePaletteRampReturn:       ; was: locret_22074
                rts
; End of function UnreferencedCreditsGlyph_UpdatePaletteRamp
; ---------------------------------------------------------------------------
CreditsGlyph_PaletteRamp:   dc.w    $222, $444, $666, $888, $AAA, $CCC, $EEE  ; was: word_22076

; Collapses the orbit radius, then derives the hold timer from the record delay
CreditsGlyph_CollapseOrbitAndSetHold:                   ; was: sub_22084
                subi.w  #$10,$4C(a5)
                bsr.w   CreditsGlyph_ProjectOrbitPosition
                subq.w  #2,$4E(a5)
                bpl.s   CreditsGlyph_CollapseOrbitReturn
                move.w  $46(a5),d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$48(a5)
                addq.w  #2,4(a5)
CreditsGlyph_CollapseOrbitReturn:                       ; was: locret_220A4
                rts
; End of function CreditsGlyph_CollapseOrbitAndSetHold
; Waits for the record delay, then enables motion with positive Y velocity
CreditsGlyph_WaitAndStartFall:                          ; was: sub_220A6
                subq.w  #1,$48(a5)
                bne.s   CreditsGlyph_WaitAndStartFallReturn
                bset    #1,2(a5)
                bset    #2,2(a5)
                move.l  #$10000,$1C(a5)
                addq.w  #2,4(a5)
CreditsGlyph_WaitAndStartFallReturn:                    ; was: locret_220C4
                rts
; End of function CreditsGlyph_WaitAndStartFall
; Applies upward acceleration to the glyph's vertical velocity
CreditsGlyph_ApplyUpwardAcceleration:                   ; was: sub_220C6
                subi.l  #$800,$1C(a5)
                rts
; End of function CreditsGlyph_ApplyUpwardAcceleration
