Sound_UpdateThunk:                                      ; was: sub_82324
                                        ; Sys_VBlankEventHandler+36   p
                jmp     Sound_UpdateDriver(pc)          ; (pc)
; End of function Sound_UpdateThunk
; Attributes: thunk
; Sound driver initialization thunk jumping to Z80 loader
Sound_InitDriverThunk:                                  ; was: sub_82328
                jmp     Sound_LoadZ80Driver(pc)         ; (pc)
; End of function Sound_InitDriverThunk
; Main sound driver update loop
Sound_UpdateDriver:                                     ; was: sub_8232C
                clr.b   (SoundChannelGroupFlags).w
                tst.b   (SoundPauseState).w
                bne.w   Sound_ProcessPauseTransition
                jsr     Sound_UpdateBGMVolumeTransitions(pc)  ; (pc)
                jsr     Sound_ProcessTempoTick(pc)      ; (pc)
                jsr     Sound_UpdateMusicFadeOut(pc)    ; (pc)
                tst.l   (SoundRequestQueue).w
                beq.s   Sound_UpdateActiveChannels
                jsr     Sound_SelectPendingRequest(pc)  ; (pc)
Sound_UpdateActiveChannels:                             ; was: loc_8234E
                jsr     Sound_DispatchPendingRequest(pc)  ; (pc)
                lea     (SoundPCMChannelRecord).w,a5
                tst.b   (a5)
                bpl.s   Sound_ProcessBGMFMChannels
                jsr     Sound_ProcessPCMSequence(pc)    ; (pc)
Sound_ProcessBGMFMChannels:                             ; was: loc_8235E
                clr.b   (SoundPCMEventFlag).w
                moveq   #5,d7
Sound_ProcessNextBGMFMChannel:                          ; was: loc_82364
                adda.w  #$30,a5                         ; '0'
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMFMChannelLoop
                jsr     Sound_ProcessChannel(pc)        ; (pc)
Sound_ContinueBGMFMChannelLoop:                         ; was: loc_82370
                dbf     d7,Sound_ProcessNextBGMFMChannel
                moveq   #2,d7
Sound_ProcessBGMPSGChannels:                            ; was: loc_82376
                adda.w  #$30,a5                         ; '0'
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMPSGChannelLoop
                jsr     Sound_ProcessPSGChannel(pc)     ; (pc)
Sound_ContinueBGMPSGChannelLoop:                        ; was: loc_82382
                dbf     d7,Sound_ProcessBGMPSGChannels
                move.b  #$80,(SoundChannelGroupFlags).w
                moveq   #2,d7
Sound_ProcessSFXFMChannels:                             ; was: loc_8238E
                adda.w  #$30,a5                         ; '0'
                tst.b   (a5)
                bpl.s   Sound_ContinueSFXFMChannelLoop
                jsr     Sound_ProcessChannel(pc)        ; (pc)
Sound_ContinueSFXFMChannelLoop:                         ; was: loc_8239A
                dbf     d7,Sound_ProcessSFXFMChannels
                moveq   #2,d7
Sound_ProcessSFXPSGChannels:                            ; was: loc_823A0
                adda.w  #$30,a5                         ; '0'
                tst.b   (a5)
                bpl.s   Sound_ContinueSFXPSGChannelLoop
                jsr     Sound_ProcessPSGChannel(pc)     ; (pc)
Sound_ContinueSFXPSGChannelLoop:                        ; was: loc_823AC
                dbf     d7,Sound_ProcessSFXPSGChannels
                move.b  #$40,(SoundChannelGroupFlags).w  ; '@'
                moveq   #1,d7
Sound_ProcessSpecialSFXChannels:                        ; was: loc_823B8
                adda.w  #$30,a5                         ; '0'
                tst.b   (a5)
                bpl.s   Sound_ContinueSpecialSFXChannelLoop
                tst.b   1(a5)
                bmi.s   Sound_ProcessSpecialSFXPSGChannel
                jsr     Sound_ProcessChannel(pc)        ; (pc)
                bra.s   Sound_ContinueSpecialSFXChannelLoop
; ---------------------------------------------------------------------------
Sound_ProcessSpecialSFXPSGChannel:                      ; was: loc_823CC
                jsr     Sound_ProcessPSGChannel(pc)     ; (pc)
; Main driver update loop iteration
Sound_ContinueSpecialSFXChannelLoop:                    ; was: loc_823D0
                                        ; Sound_UpdateDriver+9E   j
                dbf     d7,Sound_ProcessSpecialSFXChannels
                rts
; End of function Sound_UpdateDriver
; Process the DAC/PCM sequence and submit eligible samples to the Z80 driver
Sound_ProcessPCMSequence:                               ; was: sub_823D6
                subq.b  #1,$E(a5)
                bne.w   Sound_ProcessPCMSequenceReturn
                move.b  #$80,(SoundPCMEventFlag).w
                movea.l 4(a5),a4
Sound_ReadPCMSequenceCommand:                           ; was: loc_823E8
                moveq   #0,d5
                move.b  (a4)+,d5
                cmpi.b  #$E0,d5
                bcs.s   Sound_DecodePCMSequenceEvent
                jsr     Sound_DispatchSequenceCommand(pc)  ; (pc)
                bra.s   Sound_ReadPCMSequenceCommand
; ---------------------------------------------------------------------------
Sound_DecodePCMSequenceEvent:                           ; was: loc_823F8
                tst.b   d5
                bpl.s   Sound_CalculatePCMSequenceDuration
                move.b  d5,$10(a5)
                move.b  (a4)+,d5
                bpl.s   Sound_CalculatePCMSequenceDuration
                subq.w  #1,a4
                move.b  $F(a5),$E(a5)
                bra.s   Sound_SavePCMSequencePosition
; ---------------------------------------------------------------------------
Sound_CalculatePCMSequenceDuration:                     ; was: loc_8240E
                                        ; Sound_ProcessPCMSequence+2C   j
                jsr     Sound_CalculateDuration(pc)     ; (pc)
Sound_SavePCMSequencePosition:                          ; was: loc_82412
                move.l  a4,4(a5)
                moveq   #0,d0
                move.b  $10(a5),d0
                subi.b  #$81,d0
                bcs.s   Sound_ProcessPCMSequenceReturn
                ext.w   d0
                asl.w   #3,d0
                lea     Sound_PCMSampleDescriptors(pc,d0.w),a3
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForPCMZ80Bus:                                 ; was: loc_82438
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForPCMZ80Bus
                tst.b   (Z80DACRequestState).l
                bmi.s   Sound_ReleasePCMZ80Bus
                move.b  (Z80DACStatus).l,d0
                andi.b  #$C0,d0
                move.b  5(a3),d1
                andi.b  #$C0,d1
                cmp.b   d0,d1
                bcs.w   Sound_ReleasePCMZ80Bus
                move.b  #1,(Z80DACRequestState).l
                move.b  (a3)+,(Z80DACCommandByte0).l
                move.b  (a3)+,(Z80DACCommandByte1).l
                move.b  (a3)+,(Z80DACCommandByte2).l
                move.b  (a3)+,(Z80DACCommandByte3).l
                move.b  (a3)+,(Z80DACCommandByte4).l
                move.b  (a3)+,(Z80DACCommandByte5).l
                move.b  $27(a5),(Z80DACPanning).l
Sound_ReleasePCMZ80Bus:                                 ; was: loc_82496
                                        ; Sound_ProcessPCMSequence+88   j
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
Sound_ProcessPCMSequenceReturn:                         ; was: locret_824A0
                                        ; Sound_ProcessPCMSequence+4A   j
                rts
; End of function Sound_ProcessPCMSequence
; ---------------------------------------------------------------------------
Sound_PCMSampleDescriptors: dc.w    (Sound_PCMBank1 >> $8)  ; was: word_824A2
                dc.w    $80, $500, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $480, $200, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $880, $100, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $C80, $700, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1080, $700, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1480, $100, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1880, $D00, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1C80, $100, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1080, $300, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1080, $900, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $1080, $F00, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2080, $A00, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $1700, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $800, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $1000, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $D00, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $600, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2880, $100, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2C80, $100, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $3080, $500, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $800, 0
                dc.w    (Sound_PCMBank1 >> $8)
                dc.w    $2480, $E00, 0

; Processes individual sound channel state
Sound_ProcessChannel:                                   ; was: sub_82552
                                        ; Sound_UpdateDriver+6A   p
                subq.b  #1,$E(a5)
                bne.s   Sound_UpdateFMChannelEffects
                bclr    #4,(a5)
                jsr     Sound_ParseTrackData(pc)        ; (pc)
                jsr     Sound_UpdateChannelFrequency(pc)  ; (pc)
                jsr     Sound_TriggerPanAnimationForNote(pc)  ; (pc)
                bra.w   Sound_SendFMKeyOn
; ---------------------------------------------------------------------------
; Update note timeout, pan animation, and vibrato between FM sequence events
Sound_UpdateFMChannelEffects:                           ; was: loc_8256C
                jsr     Sound_HandleNoteTimer(pc)       ; (pc)
                jsr     Sound_UpdatePanAnimation(pc)    ; (pc)
                jsr     Sound_ProcessVibrato(pc)        ; (pc)
                bra.w   Sound_UpdateSustainedFMFrequency
; End of function Sound_ProcessChannel
; Parses and interprets sound track data
Sound_ParseTrackData:                                   ; was: sub_8257C
                movea.l 4(a5),a4
                bclr    #1,(a5)
Sound_ReadFMSequenceCommand:                            ; was: loc_82584
                moveq   #0,d5
                move.b  (a4)+,d5
                cmpi.b  #$E0,d5
                bcs.s   Sound_DecodeFMSequenceEvent
                jsr     Sound_DispatchSequenceCommand(pc)  ; (pc)
                bra.s   Sound_ReadFMSequenceCommand
; ---------------------------------------------------------------------------
Sound_DecodeFMSequenceEvent:                            ; was: loc_82594
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
                tst.b   d5
                bpl.s   Sound_ParseNoteData
                jsr     Sound_CalculatePitch(pc)        ; (pc)
                move.b  (a4)+,d5
                bpl.s   Sound_ParseNoteData
                subq.w  #1,a4
                bra.w   Sound_SaveChannelState
; ---------------------------------------------------------------------------
; Parses note data and calculates duration
Sound_ParseNoteData:                                    ; was: loc_825AA
                                        ; Sound_ParseTrackData+26   j
                jsr     Sound_CalculateDuration(pc)     ; (pc)
                bra.w   Sound_SaveChannelState
; End of function Sound_ParseTrackData
; Calculates note pitch and frequency
Sound_CalculatePitch:                                   ; was: sub_825B2
                subi.b  #$80,d5
                beq.s   Sound_MarkFMChannelRest
                add.b   8(a5),d5
                andi.l  #$7F,d5
                divu.w  #$C,d5
                swap    d5
                lsl.w   #1,d5
                lea     Sound_FMNoteFrequencyTable(pc),a0
                move.w  (a0,d5.w),d6
                swap    d5
                andi.w  #7,d5
                moveq   #$B,d0
                lsl.w   d0,d5
                or.w    d5,d6
                move.w  d6,$10(a5)
                rts
; End of function Sound_CalculatePitch
; Calculates note duration timing
Sound_CalculateDuration:                                ; was: sub_825E4
                                        ; sub_8257C:loc_825AA   p
                move.b  d5,d0
                move.b  2(a5),d1
Sound_MultiplyDurationByTickScale:                      ; was: loc_825EA
                subq.b  #1,d1
                beq.s   Sound_StoreChannelDuration
                add.b   d5,d0
                bra.s   Sound_MultiplyDurationByTickScale
; ---------------------------------------------------------------------------
Sound_StoreChannelDuration:                             ; was: loc_825F2
                move.b  d0,$F(a5)
                move.b  d0,$E(a5)
                rts
; End of function Sound_CalculateDuration
; Mark a rest event and clear the FM pitch word
Sound_MarkFMChannelRest:                                ; was: sub_825FC
                bset    #1,(a5)
                clr.w   $10(a5)
; End of function Sound_MarkFMChannelRest
; Saves channel state and envelope data
Sound_SaveChannelState:                                 ; was: sub_82604
                                        ; Sound_ParseTrackData+32   j
                move.l  a4,4(a5)
                move.b  $F(a5),$E(a5)
                btst    #4,(a5)
                bne.s   Sound_SaveChannelStateReturn
                move.b  $13(a5),$12(a5)
                clr.b   $C(a5)
                clr.b   $26(a5)
                clr.b   3(a5)
                btst    #7,$A(a5)
                beq.s   Sound_SaveChannelStateReturn
                movea.l $14(a5),a0
                move.b  (a0)+,$18(a5)
                move.b  (a0)+,$19(a5)
                move.b  (a0)+,$1A(a5)
                move.b  (a0)+,d0
                lsr.b   #1,d0
                move.b  d0,$1B(a5)
                clr.w   $1C(a5)
Sound_SaveChannelStateReturn:                           ; was: locret_8264A
                                        ; Sound_SaveChannelState+28   j
                rts
; End of function Sound_SaveChannelState
; Handles sound channel note timer countdown and restarts playback
Sound_HandleNoteTimer:                                  ; was: sub_8264C
                                        ; sub_84A70:loc_84A86   p
                tst.b   $12(a5)
                beq.s   Sound_HandleNoteTimerReturn
                subq.b  #1,$12(a5)
                bne.s   Sound_HandleNoteTimerReturn
                bset    #1,(a5)
                tst.b   1(a5)
                bmi.w   Sound_HandlePSGNoteTimeout
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
                addq.w  #4,sp
                rts
; ---------------------------------------------------------------------------
Sound_HandlePSGNoteTimeout:                             ; was: loc_8266C
                jsr     Sound_MutePSGIfNotOverridden(pc)  ; (pc)
                addq.w  #4,sp
Sound_HandleNoteTimerReturn:                            ; was: locret_82672
                                        ; Sound_HandleNoteTimer+A   j
                rts
; End of function Sound_HandleNoteTimer
; Processes sound vibrato effect modulating pitch with oscillation
Sound_ProcessVibrato:                                   ; was: sub_82674
                                        ; Sound_ProcessPSGChannel+1E   p
                btst    #7,$A(a5)
                beq.s   Sound_ProcessVibratoReturn
                tst.b   $18(a5)
                beq.s   Sound_CountDownVibratoStepDelay
                subq.b  #1,$18(a5)
                rts
; ---------------------------------------------------------------------------
Sound_CountDownVibratoStepDelay:                        ; was: loc_82688
                subq.b  #1,$19(a5)
                beq.s   Sound_ReloadVibratoStep
                rts
; ---------------------------------------------------------------------------
Sound_ReloadVibratoStep:                                ; was: loc_82690
                movea.l $14(a5),a0
                move.b  1(a0),$19(a5)
                tst.b   $1B(a5)
                bne.s   Sound_ApplyVibratoOffset
                move.b  3(a0),$1B(a5)
                neg.b   $1A(a5)
                rts
; ---------------------------------------------------------------------------
; Applies vibrato offset to frequency
Sound_ApplyVibratoOffset:                               ; was: loc_826AC
                subq.b  #1,$1B(a5)
                move.b  $1A(a5),d6
                ext.w   d6
                add.w   $1C(a5),d6
                move.w  d6,$1C(a5)
                add.w   $10(a5),d6
Sound_ProcessVibratoReturn:                             ; was: locret_826C2
                rts
; End of function Sound_ProcessVibrato
; Updates FM channel frequency registers with calculated pitch
Sound_UpdateChannelFrequency:                           ; was: sub_826C4
                move.w  $10(a5),d6
                bne.s   Sound_CheckFMFrequencyWriteFlags
                bset    #1,(a5)
                rts
; ---------------------------------------------------------------------------
Sound_UpdateSustainedFMFrequency:                       ; was: loc_826D0
                tst.b   $A(a5)
                beq.w   Sound_UpdateChannelFrequencyReturn
Sound_CheckFMFrequencyWriteFlags:                       ; was: loc_826D8
                btst    #1,(a5)
                bne.w   Sound_UpdateChannelFrequencyReturn
                btst    #2,(a5)
                bne.w   Sound_UpdateChannelFrequencyReturn
                jsr     Sound_ApplyPitchEffects(pc)     ; (pc)
                tst.b   (SoundFM3SpecialMode).w
                beq.s   Sound_WriteFrequencyBytes
                cmpi.b  #2,1(a5)
                beq.w   Sound_UpdateFMOperators
; Writes frequency bytes to YM2612
Sound_WriteFrequencyBytes:                              ; was: loc_826FC
                move.w  d6,d1
                lsr.w   #8,d1
                move.b  #$A4,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                move.b  d6,d1
                move.b  #$A0,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
Sound_UpdateChannelFrequencyReturn:                     ; was: locret_82712
                                        ; Sound_UpdateChannelFrequency+18   j
                rts
; End of function Sound_UpdateChannelFrequency
; Applies pitch effects including detune transpose and modulation to frequency
Sound_ApplyPitchEffects:                                ; was: sub_82714
                                        ; Sound_UpdatePSGChannelFrequency+1E   p
                moveq   #0,d6
                move.b  $A(a5),d0
                andi.w  #$7F,d0
                beq.s   Sound_ApplyDetuneAndBasePitch
                lea     Sound_PitchEnvelopePointerTable(pc),a0
                subq.w  #1,d0
                lsl.w   #2,d0
                movea.l (a0,d0.w),a0
Sound_ReadPitchEnvelopeCommand:                         ; was: loc_8272C
                                        ; Sound_RepeatPitchEnvelopeValue+4   j
                moveq   #0,d0
                move.b  $26(a5),d0
                addq.b  #1,$26(a5)
                move.b  (a0,d0.w),d6
                bpl.s   Sound_ScalePitchEnvelopeValue
                cmpi.b  #$80,d6
                beq.s   Sound_RestartPitchEnvelope
                cmpi.b  #$81,d6
                beq.s   Sound_RepeatPitchEnvelopeValue
                cmpi.b  #$83,d6
                beq.s   Sound_EndPitchEnvelopeWithRest
                cmpi.b  #$82,d6
                beq.s   Sound_JumpPitchEnvelope
                cmpi.b  #$84,d6
                beq.s   Sound_AddPitchEnvelopeTranspose
Sound_ScalePitchEnvelopeValue:                          ; was: loc_8275A
                ext.w   d6
                move.b  3(a5),d0
                ext.w   d0
                mulu.w  d0,d6
Sound_ApplyDetuneAndBasePitch:                          ; was: loc_82764
                move.b  $1E(a5),d0
                ext.w   d0
                add.w   d0,d6
                add.w   $10(a5),d6
                tst.b   $A(a5)
                bpl.s   Sound_ApplyPitchEffectsReturn
                add.w   $1C(a5),d6
Sound_ApplyPitchEffectsReturn:                          ; was: locret_8277A
                rts
; End of function Sound_ApplyPitchEffects
; Statically unreferenced stack-skip helper between pitch-envelope commands
; UNKNOWN CODE-005: no static entry path; see docs/unknowns.md
Sound_PitchEnvelopeUnreferencedSkipReturn:              ; was: sub_8277C
                addq.w  #4,sp
                rts
; End of function Sound_PitchEnvelopeUnreferencedSkipReturn
; Restart the pitch-envelope cursor after command $80
Sound_RestartPitchEnvelope:                             ; was: sub_82780
                clr.b   $26(a5)
                bra.s   Sound_ReadPitchEnvelopeCommand
; End of function Sound_RestartPitchEnvelope
; Repeat the preceding pitch-envelope value after command $81
Sound_RepeatPitchEnvelopeValue:                         ; was: sub_82786
                subq.b  #2,$26(a5)
                bra.s   Sound_ReadPitchEnvelopeCommand
; End of function Sound_RepeatPitchEnvelopeValue
; End a pitch envelope with a rest after command $83
Sound_EndPitchEnvelopeWithRest:                         ; was: sub_8278C
                bset    #1,(a5)
                tst.b   1(a5)
                bmi.s   Sound_EndPSGPitchEnvelopeWithRest
                bra.w   Sound_SendFMKeyOffIfAllowed
; ---------------------------------------------------------------------------
Sound_EndPSGPitchEnvelopeWithRest:                      ; was: loc_8279A
                bra.w   Sound_MutePSGIfNotOverridden
; End of function Sound_EndPitchEnvelopeWithRest
; Jump the pitch-envelope cursor after command $82
Sound_JumpPitchEnvelope:                                ; was: sub_8279E
                move.b  1(a0,d0.w),$26(a5)
                bra.s   Sound_ReadPitchEnvelopeCommand
; End of function Sound_JumpPitchEnvelope
; Add pitch-envelope transposition after command $84
Sound_AddPitchEnvelopeTranspose:                        ; was: sub_827A6
                move.b  1(a0,d0.w),d0
                add.b   d0,3(a5)
                addq.b  #1,$26(a5)
                bra.w   Sound_ReadPitchEnvelopeCommand
; End of function Sound_AddPitchEnvelopeTranspose
; Updates YM2612 frequency registers for all 4 FM operators per channel
Sound_UpdateFMOperators:                                ; was: sub_827B6
                lea     Sound_FM3OperatorFrequencyRegisters(pc),a1
                lea     (SoundBGMFM3Offsets).w,a2
                tst.b   (SoundChannelGroupFlags).w
                beq.s   Sound_SelectFM3FrequencyShadowBank
                lea     (SoundSFXFM3Offsets).w,a2
Sound_SelectFM3FrequencyShadowBank:                     ; was: loc_827C8
                moveq   #3,d5
Sound_WriteNextFM3OperatorFrequency:                    ; was: loc_827CA
                move.w  d6,d1
                move.w  (a2)+,d0
                add.w   d0,d1
                move.w  d1,d3
                lsr.w   #8,d1
                move.b  (a1)+,d0
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                move.b  d3,d1
                move.b  (a1)+,d0
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                dbf     d5,Sound_WriteNextFM3OperatorFrequency
                rts
; End of function Sound_UpdateFMOperators
; ---------------------------------------------------------------------------
Sound_FM3OperatorFrequencyRegisters:    dc.b    $AD, $A9, $AC, $A8, $AE, $AA, $A6, $A2  ; was: byte_827E8

; Dispatch the note-trigger behavior for the configured pan-animation mode
Sound_TriggerPanAnimationForNote:                       ; was: sub_827F0
                btst    #1,(a5)
                bne.s   Sound_PanAnimationNoteModeDispatch
                moveq   #0,d0
                move.b  $1F(a5),d0
                lsl.w   #1,d0
                jmp     Sound_PanAnimationNoteModeDispatch(pc,d0.w)
; End of function Sound_TriggerPanAnimationForNote
Sound_PanAnimationNoteModeDispatch:
                                        ; Sound_TriggerPanAnimationForNote+E   j
                rts
; ---------------------------------------------------------------------------
                bra.s   Sound_UpdatePanAnimationStepTimer
; ---------------------------------------------------------------------------
                bra.s   Sound_RestartPanAnimation
; ---------------------------------------------------------------------------
                bra.s   Sound_RestartPanAnimation
; End of function Sound_PanAnimationNoteModeDispatch

; Dispatch the per-tick behavior for the configured pan-animation mode
Sound_UpdatePanAnimation:                               ; was: sub_8280A
                btst    #1,(a5)
                bne.s   Sound_PanAnimationTickModeDispatch
                moveq   #0,d0
                move.b  $1F(a5),d0
                lsl.w   #1,d0
                jmp     Sound_PanAnimationTickModeDispatch(pc,d0.w)
; ---------------------------------------------------------------------------
Sound_PanAnimationTickModeDispatch:
                                        ; Sound_UpdatePanAnimation+E   j
                rts
; ---------------------------------------------------------------------------
                rts
; ---------------------------------------------------------------------------
                bra.s   Sound_UpdatePanAnimationStepTimer
; ---------------------------------------------------------------------------
                bra.s   Sound_UpdatePanAnimationStepTimer
; End of function Sound_UpdatePanAnimation
; Restart a pan animation and immediately evaluate its first frame
Sound_RestartPanAnimation:                              ; was: sub_82824
                                        ; Sound_PanAnimationNoteModeDispatch+6   j
                move.b  $23(a5),$24(a5)
                clr.b   $21(a5)
Sound_UpdatePanAnimationStepTimer:                      ; was: loc_8282E
                                        ; Sound_UpdatePanAnimation+16   j
                move.b  $24(a5),d0
                cmp.b   $23(a5),d0
                bne.s   Sound_ApplyPanAnimationFrame
                move.b  $22(a5),d3
                cmp.b   $21(a5),d3
                bpl.s   Sound_AdvancePanAnimationStep
                cmpi.b  #2,$1F(a5)
                beq.s   Sound_UpdatePanAnimationReturn
                clr.b   $21(a5)
Sound_AdvancePanAnimationStep:                          ; was: loc_8284E
                clr.b   $24(a5)
                addq.b  #1,$21(a5)
; Resolve and apply the current pan-animation frame
Sound_ApplyPanAnimationFrame:                           ; was: loc_82856
                moveq   #0,d0
                move.b  $20(a5),d0
                subq.w  #1,d0
                lsl.w   #2,d0
                movea.l Sound_PanAnimationPointerTable(pc,d0.w),a0
                moveq   #0,d0
                move.b  $21(a5),d0
                subq.w  #1,d0
                move.b  (a0,d0.w),d1
                move.b  $27(a5),d0
                andi.b  #$37,d0                         ; '7'
                or.b    d0,d1
                jsr     Sound_WriteChannelPanAndAMS(pc)  ; (pc)
                addq.b  #1,$24(a5)
Sound_UpdatePanAnimationReturn:                         ; was: locret_82882
                rts
; End of function Sound_RestartPanAnimation
; ---------------------------------------------------------------------------
Sound_PanAnimationPointerTable: dc.l    Sound_PanAnimationSequence1
                dc.l    Sound_PanAnimationSequence2
                dc.l    Sound_PanAnimationSequence3
Sound_PanAnimationSequence1:    dc.b    $40, $80
Sound_PanAnimationSequence2:    dc.b    $40, $C0, $80
Sound_PanAnimationSequence3:    dc.b    $C0, $80, $C0, $40, 0

; Write pan/AMS state to the PCM mailbox or the current FM channel
Sound_WriteChannelPanAndAMS:                            ; was: sub_8289A
                                        ; Sound_SetSequencePanning+16   j
                btst    #2,(a5)
                bne.s   Sound_WriteChannelPanAndAMSReturn
                cmpi.b  #6,1(a5)
                bne.w   Sound_WriteFMChannelPanAndAMS
                cmpa.l  #$40,a5                         ; '@'
                beq.w   Sound_WriteChannelPanAndAMSReturn
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForPanUpdateZ80Bus:                           ; was: loc_828C2
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForPanUpdateZ80Bus
                move.b  (Z80DACRequestState).l,d0
                beq.w   Sound_ReleasePanUpdateZ80Bus
                move.b  $27(a5),(Z80DACPanningUpdate).l
Sound_ReleasePanUpdateZ80Bus:                           ; was: loc_828DE
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                tst.b   d0
                bne.s   Sound_WriteChannelPanAndAMSReturn
Sound_WriteFMChannelPanAndAMS:                          ; was: loc_828EC
                move.b  #$B4,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
Sound_WriteChannelPanAndAMSReturn:                      ; was: locret_828F4
                                        ; Sound_WriteChannelPanAndAMS+16   j
                rts
; End of function Sound_WriteChannelPanAndAMS
; Apply pause or resume transitions requested by the input/VBlank path
Sound_ProcessPauseTransition:                           ; was: sub_828F6
                cmpi.b  #$FF,(SoundPauseState).w
                bne.w   Sound_BeginPauseTransition
                rts
; ---------------------------------------------------------------------------
Sound_BeginPauseTransition:                             ; was: loc_82902
                tst.b   (SoundPauseState).w
                bmi.s   Sound_ResumeFromPause
                move.b  #$FF,(SoundPauseState).w
                move    sr,-(sp)
                ori     #$700,sr
Sound_RequestZ80BusForPause:                            ; was: loc_82914
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusForPause:                            ; was: loc_8291C
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusForPause
                tst.b   (Z80DriverBusy).l
                beq.s   Sound_MuteChannelsForPause
                move.w  #0,(IO_Z80BUS).l
                bsr.w   Sound_DelayForZ80BusRetry
                bra.s   Sound_RequestZ80BusForPause
; ---------------------------------------------------------------------------
Sound_MuteChannelsForPause:                             ; was: loc_8293C
                move    (sp)+,sr
                lea     (SoundFMLevelShadows).w,a1
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                move.l  (a1)+,-(sp)
                jsr     Sound_SetAllFMOperatorLevelsMaximum(pc)  ; (pc)
                lea     (SoundFMShadowsEnd).w,a1
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                move.l  (sp)+,-(a1)
                bra.w   Sound_MuteAllPSGChannels
; ---------------------------------------------------------------------------
Sound_ResumeFromPause:                                  ; was: loc_8296E
                clr.b   (SoundPauseState).w
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                lea     (SoundFMShadowIndexBase).w,a1
                moveq   #2,d2
Sound_RestoreFMRegisterBankLoop:                        ; was: loc_82988
                moveq   #$40,d0                         ; '@'
                add.w   d2,d0
                moveq   #3,d3
Sound_RestoreFMOperatorRegistersLoop:                   ; was: loc_8298E
                move.b  (a1,d0.w),d1
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                move.b  $10(a1,d0.w),d1
                jsr     Sound_WriteYM2612Port1(pc)      ; (pc)
                addq.w  #4,d0
                dbf     d3,Sound_RestoreFMOperatorRegistersLoop
                dbf     d2,Sound_RestoreFMRegisterBankLoop
                rts
; End of function Sound_ProcessPauseTransition
; End of sound driver core
