Sound_ProcessPSGChannel:                                ; was: sub_84A70
                                        ; Sound_UpdateDriver+7C   p
                subq.b  #1,$E(a5)
                bne.s   Sound_UpdateSustainedPSGChannel
                bclr    #4,(a5)
                jsr     Sound_ParsePSGSequenceData(pc)  ; (pc)
                jsr     Sound_UpdatePSGChannelFrequency(pc)  ; (pc)
                bra.w   Sound_ApplyPSGVolumeEnvelope
; ---------------------------------------------------------------------------
; Update note timeout, volume envelope, and pitch effects between PSG events
Sound_UpdateSustainedPSGChannel:                        ; was: loc_84A86
                jsr     Sound_HandleNoteTimer(pc)       ; (pc)
                jsr     Sound_UpdatePSGVolumeEnvelope(pc)  ; (pc)
                jsr     Sound_ProcessVibrato(pc)        ; (pc)
                bra.w   Sound_CheckSustainedPSGPitchEnvelope
; End of function Sound_ProcessPSGChannel
; Parse PSG sequence commands, notes, rests, and durations
Sound_ParsePSGSequenceData:                             ; was: sub_84A96
                bclr    #1,(a5)
                movea.l 4(a5),a4
Sound_ReadPSGSequenceCommand:                           ; was: loc_84A9E
                moveq   #0,d5
                move.b  (a4)+,d5
                cmpi.b  #$E0,d5
                bcs.s   Sound_DecodePSGSequenceEvent
                jsr     Sound_DispatchSequenceCommand(pc)  ; (pc)
                bra.s   Sound_ReadPSGSequenceCommand
; ---------------------------------------------------------------------------
Sound_DecodePSGSequenceEvent:                           ; was: loc_84AAE
                tst.b   d5
                bpl.s   Sound_ParsePSGSequenceDuration
                jsr     Sound_DecodePSGSequenceNote(pc)  ; (pc)
                move.b  (a4)+,d5
                tst.b   d5
                bpl.s   Sound_ParsePSGSequenceDuration
                subq.w  #1,a4
                bra.w   Sound_SaveChannelState
; ---------------------------------------------------------------------------
; Parse a PSG event duration and save the updated sequence cursor
Sound_ParsePSGSequenceDuration:                         ; was: loc_84AC2
                                        ; Sound_ParsePSGSequenceData+24   j
                jsr     Sound_CalculateDuration(pc)     ; (pc)
                bra.w   Sound_SaveChannelState
; Decode a PSG note into its tone period or mark the channel resting
Sound_DecodePSGSequenceNote:                            ; was: sub_84ACA
                subi.b  #$81,d5
                bcs.s   Sound_MarkPSGChannelRest
                add.b   8(a5),d5
                andi.w  #$7F,d5
                lsl.w   #1,d5
                lea     Sound_PSGNotePeriodTable(pc),a0
                move.w  (a0,d5.w),$10(a5)
                bra.w   Sound_SaveChannelState
; ---------------------------------------------------------------------------
Sound_MarkPSGChannelRest:                               ; was: loc_84AE8
                bset    #1,(a5)
                move.w  #$FFFF,$10(a5)
                jsr     Sound_SaveChannelState(pc)      ; (pc)
                bra.w   Sound_MutePSGIfNotOverridden
; End of function Sound_DecodePSGSequenceNote
; Updates PSG channel frequency with pitch calculation
Sound_UpdatePSGChannelFrequency:                        ; was: sub_84AFA
                move.w  $10(a5),d6
                bpl.s   Sound_ApplyPSGFrequencyEffects
                bset    #1,(a5)
                rts
; ---------------------------------------------------------------------------
Sound_CheckSustainedPSGPitchEnvelope:                   ; was: loc_84B06
                tst.b   $A(a5)
                beq.s   Sound_UpdatePSGChannelFrequencyReturn
Sound_ApplyPSGFrequencyEffects:                         ; was: loc_84B0C
                btst    #1,(a5)
                bne.s   Sound_UpdatePSGChannelFrequencyReturn
                btst    #2,(a5)
                bne.s   Sound_UpdatePSGChannelFrequencyReturn
                jsr     Sound_ApplyPitchEffects(pc)     ; (pc)
                move.b  1(a5),d0
                cmpi.b  #$E0,d0
                bne.s   Sound_WritePSGFrequency
                move.b  #$C0,d0
; Writes frequency to PSG chip
Sound_WritePSGFrequency:                                ; was: loc_84B2A
                move.w  d6,d1
                andi.b  #$F,d1
                or.b    d1,d0
                lsr.w   #4,d6
                andi.b  #$3F,d6                         ; '?'
                move.b  d0,(VDP_PSG).l
                move.b  d6,(VDP_PSG).l
Sound_UpdatePSGChannelFrequencyReturn:                  ; was: locret_84B44
                                        ; Sound_UpdatePSGChannelFrequency+16   j
                rts
; End of function Sound_UpdatePSGChannelFrequency
; Advance the selected PSG volume envelope
Sound_UpdatePSGVolumeEnvelope:                          ; was: sub_84B46
                tst.b   $B(a5)
                beq.w   Sound_ApplyPSGVolumeReturn
Sound_ApplyPSGVolumeEnvelope:                           ; was: loc_84B4E
                move.b  9(a5),d6
                moveq   #0,d0
                move.b  $B(a5),d0
                beq.s   Sound_ApplyPSGVolume
                lea     Sound_PSGVolumeEnvelopePointerTable(pc),a0
                subq.w  #1,d0
                lsl.w   #2,d0
                movea.l (a0,d0.w),a0
Sound_ReadPSGVolumeEnvelopeCommand:                     ; was: loc_84B66
                                        ; Sound_RestartPSGVolumeEnvelope+4   j
                moveq   #0,d0
                move.b  $C(a5),d0
                addq.b  #1,$C(a5)
                move.b  (a0,d0.w),d0
                bpl.s   Sound_ApplyPSGVolumeEnvelopeValue
                cmpi.b  #$83,d0
                beq.s   Sound_EndPSGVolumeEnvelopeWithMute
                cmpi.b  #$81,d0
                beq.s   Sound_RepeatPSGVolumeEnvelopeValue
                cmpi.b  #$82,d0
                beq.s   Sound_JumpPSGVolumeEnvelope
                cmpi.b  #$80,d0
                beq.s   Sound_RestartPSGVolumeEnvelope
Sound_ApplyPSGVolumeEnvelopeValue:                      ; was: loc_84B8E
                add.w   d0,d6
                cmpi.b  #$10,d6
                bcs.s   Sound_ApplyPSGVolume
                moveq   #$F,d6
; End of function Sound_UpdatePSGVolumeEnvelope
; Applies volume to PSG channel with mute check
Sound_ApplyPSGVolume:                                   ; was: sub_84B98
                                        ; Sound_UpdateBGMVolumeTransitions+114   p
                btst    #1,(a5)
                bne.s   Sound_ApplyPSGVolumeReturn
                btst    #2,(a5)
                bne.s   Sound_ApplyPSGVolumeReturn
                btst    #4,(a5)
                bne.s   Sound_CheckPSGNoteStopHold
Sound_WritePSGVolume:                                   ; was: loc_84BAA
                                        ; Sound_ApplyPSGVolume+2C   j
                or.b    1(a5),d6
                addi.b  #$10,d6
                move.b  d6,(VDP_PSG).l
Sound_ApplyPSGVolumeReturn:                             ; was: locret_84BB8
                                        ; Sound_ApplyPSGVolume+4   j
                rts
; ---------------------------------------------------------------------------
Sound_CheckPSGNoteStopHold:                             ; was: loc_84BBA
                tst.b   $13(a5)
                beq.s   Sound_WritePSGVolume
                tst.b   $12(a5)
                bne.s   Sound_WritePSGVolume
                rts
; End of function Sound_ApplyPSGVolume
; End PSG volume-envelope playback and mute the channel after command $83
Sound_EndPSGVolumeEnvelopeWithMute:                     ; was: sub_84BC8
                subq.b  #2,$C(a5)
                bset    #1,(a5)
                bra.w   Sound_MutePSGIfNotOverridden
; End of function Sound_EndPSGVolumeEnvelopeWithMute
; Repeat the preceding PSG volume-envelope value after command $81
Sound_RepeatPSGVolumeEnvelopeValue:                     ; was: sub_84BD4
                subq.b  #2,$C(a5)
                rts
; End of function Sound_RepeatPSGVolumeEnvelopeValue
; Jump the PSG volume-envelope cursor after command $82
Sound_JumpPSGVolumeEnvelope:                            ; was: sub_84BDA
                move.b  1(a0,d0.w),$C(a5)
                bra.s   Sound_ReadPSGVolumeEnvelopeCommand
; End of function Sound_JumpPSGVolumeEnvelope
; Restart the PSG volume envelope after command $80
Sound_RestartPSGVolumeEnvelope:                         ; was: sub_84BE2
                clr.b   $C(a5)
                bra.w   Sound_ReadPSGVolumeEnvelopeCommand
; End of function Sound_RestartPSGVolumeEnvelope
; Mute the current PSG channel unless a live SFX override owns its output
Sound_MutePSGIfNotOverridden:                           ; was: sub_84BEA
                                        ; Sound_EndPSGPitchEnvelopeWithRest   j
                btst    #2,(a5)
                bne.s   Sound_MutePSGChannelReturn
; End of function Sound_MutePSGIfNotOverridden
; Mutes PSG channel by setting maximum attenuation
Sound_MutePSGChannel:                                   ; was: sub_84BF0
                move.b  1(a5),d0
                ori.b   #$1F,d0
                move.b  d0,(VDP_PSG).l
Sound_MutePSGChannelReturn:                             ; was: locret_84BFE
                rts
; End of function Sound_MutePSGChannel
; Mutes all four PSG channels by writing $9F,$BF,$DF,$FF to PSG port
Sound_MuteAllPSGChannels:                               ; was: sub_84C00
                                        ; Sound_StopAllPlayback+20   j
                lea     (VDP_PSG).l,a0
                move.b  #$9F,(a0)
                move.b  #$BF,(a0)
                move.b  #$DF,(a0)
                move.b  #$FF,(a0)
                rts
; End of function Sound_MuteAllPSGChannels
; ---------------------------------------------------------------------------
; PSG tone periods indexed by the decoded note value
Sound_PSGNotePeriodTable:   dc.w    $356, $326, $2F9    ; was: word_84C18
                dc.w    $2CE, $2A5, $280
                dc.w    $25C, $23A, $21A
                dc.w    $1FB, $1DF, $1C4
                dc.w    $1AB, $193, $17D
                dc.w    $167, $153, $140
                dc.w    $12E, $11D, $10D
                dc.w    $FE, $EF, $E2
                dc.w    $D6, $C9, $BE
                dc.w    $B4, $A9, $A0
                dc.w    $97, $8F, $87
                dc.w    $7F, $78, $71
                dc.w    $6B, $65, $5F
                dc.w    $5A, $55, $50
                dc.w    $4B, $47, $43
                dc.w    $40, $3C, $39
                dc.w    $36, $33, $30
                dc.w    $2D, $2B, $28
                dc.w    $26, $24, $22
                dc.w    $20, $1F, $1D
                dc.w    $1B, $1A, $18
                dc.w    $17, $16, $15
                dc.w    $13, $12, $11
                dc.w    0
; Driver data/code interface table retained in its original ROM order
Sound_DriverInterfaceTable:
                dc.l    Sound_RequestPriorityTable
                dc.l    Sound_SpecialSFXPointerTable
                dc.l    Sound_BGMPointerTable
                dc.l    Sound_OrdinarySFXPointerTableBase
                dc.l    Sound_PitchEnvelopePointerTable
                dc.l    Sound_PSGVolumeEnvelopePointerTable
                dc.l    $A0
                dc.l    Sound_UpdateDriver
                dc.l    Sound_LowRangeSFXPointerTable
; Pitch-offset streams selected by channel field $A
Sound_PitchEnvelopePointerTable:    dc.l    Sound_PitchEnvelope_1  ; was: off_84CC8
                                        ; Sound_DriverInterfaceTable+$10   o
                dc.l    Sound_PitchEnvelope_2
                dc.l    Sound_PitchEnvelope_3
                dc.l    Sound_PitchEnvelope_4
                dc.l    Sound_PitchEnvelope_5
                dc.l    Sound_PitchEnvelope_6
                dc.l    Sound_PitchEnvelope_7
                dc.l    Sound_PitchEnvelope_8
Sound_PitchEnvelope_1:  dc.b    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E, $F  ; was: byte_84CE8
                dc.b    $10, $11, $12, $13, $14, $83
Sound_PitchEnvelope_2:  dc.b    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E, $F  ; was: byte_84CFE
                dc.b    $10, $11, $12, $13, $14, $80
Sound_PitchEnvelope_3:  dc.b    $D8, $E2, $EC, $F6, 0, $A, $14, $1E, $28, $83  ; was: byte_84D14
Sound_PitchEnvelope_4:  dc.b    $D8, $E2, $EC, $F6, 0, $A, $14, $1E, $28, $80  ; was: byte_84D1E
Sound_PitchEnvelope_6:  dc.b    4, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1  ; was: byte_84D28
Sound_PitchEnvelope_5:  dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1  ; was: byte_84D38
                dc.b    1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2
                dc.b    3, 3, 3, 3, 3, 3, 3, 3, 4, $83
Sound_PitchEnvelope_7:  dc.b    2, $83                  ; was: byte_84D62
Sound_PitchEnvelope_8:  dc.b    0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2  ; was: byte_84D64
                dc.b    3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6
                dc.b    6, 6, 6, 6, 7, 7, 7, $83
; PSG attenuation streams selected by channel field $B
Sound_PSGVolumeEnvelopePointerTable:    dc.l    Sound_PSGVolumeEnvelope_1  ; was: off_84D8C
                                        ; Sound_DriverInterfaceTable+$14   o
                dc.l    Sound_PSGVolumeEnvelope_2
                dc.l    Sound_PSGVolumeEnvelope_3
                dc.l    Sound_PSGVolumeEnvelope_4
                dc.l    Sound_PSGVolumeEnvelope_5
                dc.l    Sound_PSGVolumeEnvelope_6
                dc.l    Sound_PSGVolumeEnvelope_7
                dc.l    Sound_PSGVolumeEnvelope_8
                dc.l    Sound_PSGVolumeEnvelope_9
                dc.l    Sound_PSGVolumeEnvelope_10
Sound_PSGVolumeEnvelope_1:  dc.b    0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5  ; was: byte_84DB4
                dc.b    5, 5, 6, 6, 6, 7, $83
Sound_PSGVolumeEnvelope_2:  dc.b    0, 2, 4, 6, 8, $10, $83  ; was: byte_84DCB
Sound_PSGVolumeEnvelope_3:  dc.b    0, 0, 1, 1, 3, 3, 4, 5, $83  ; was: byte_84DD2
Sound_PSGVolumeEnvelope_4:  dc.b    0, 0, 2, 3, 4, 4, 5, 5, 5, 6, $83  ; was: byte_84DDB
Sound_PSGVolumeEnvelope_6:  dc.b    4, 4, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1  ; was: byte_84DE6
Sound_PSGVolumeEnvelope_5:  dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1  ; was: byte_84DF6
                dc.b    1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2
                dc.b    3, 3, 3, 3, 3, 3, 3, 3, 4, $83
Sound_PSGVolumeEnvelope_7:  dc.b    2, $83              ; was: byte_84E20
Sound_PSGVolumeEnvelope_8:  dc.b    0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2  ; was: byte_84E22
                dc.b    3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6
                dc.b    6, 6, 6, 6, 7, 7, 7, $83
Sound_PSGVolumeEnvelope_9:  dc.b    8, 8, 7, 7, 7, 7, 6, 6, 6, 6, 5, 5, 5, 5, 4, 4  ; was: byte_84E4A
                dc.b    4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 0, $81
Sound_PSGVolumeEnvelope_10: dc.b    8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1, 0, $81, 0  ; was: byte_84E6A
