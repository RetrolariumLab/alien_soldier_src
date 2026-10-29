; Sequence dispatch, immediate channel parameters, and FM instrument programming
; Dispatch sequence commands $E0-$FE through the ROM-ordered handler table
Sound_DispatchSequenceCommand:                          ; was: sub_83820
                                        ; Sound_ParseTrackData+12   p
                subi.w  #$E0,d5
                lsl.w   #2,d5
                jmp     Sound_SequenceCommandJumpTable(pc,d5.w)
; ---------------------------------------------------------------------------
Sound_SequenceCommandJumpTable:                         ; was: loc_8382A
                bra.w   Sound_SetSequencePanning        ; E0: panning bits
; ---------------------------------------------------------------------------
                bra.w   Sound_SetChannelDetune          ; E1: detune
; ---------------------------------------------------------------------------
                bra.w   Sound_SetCommunicationByte      ; E2: communication byte
; ---------------------------------------------------------------------------
                bra.w   Sound_SilenceFMOperatorsAndStopChannel  ; E3: silence FM operators and stop track
; ---------------------------------------------------------------------------
                bra.w   Sound_SetPanAnimation           ; E4: pan animation
; ---------------------------------------------------------------------------
                bra.w   Sound_AddChannelTypeVolumeOffset  ; E5: PSG/FM volume pair
; ---------------------------------------------------------------------------
                bra.w   Sound_AddFMVolumeOffset         ; E6: FM volume
; ---------------------------------------------------------------------------
                bra.w   Sound_HoldNextNote              ; E7: hold next note
; ---------------------------------------------------------------------------
                bra.w   Sound_SetNoteStopTimeout        ; E8: note stop timeout
; ---------------------------------------------------------------------------
                bra.w   Sound_ConfigureFMLFOAndAmplitudeModulation  ; E9: YM2612 LFO and AM
; ---------------------------------------------------------------------------
                bra.w   Sound_SetTempoReload            ; EA: tempo
; ---------------------------------------------------------------------------
                bra.w   Sound_QueueSequenceSoundRequest  ; EB: queue sound ID
; ---------------------------------------------------------------------------
                bra.w   Sound_AddPSGVolumeOffset        ; EC: PSG volume
; ---------------------------------------------------------------------------
                bra.w   Sound_WriteCurrentFMRegisterFromSequence  ; ED: current FM channel register
; ---------------------------------------------------------------------------
                bra.w   Sound_WriteYM2612Port0RegisterFromSequence  ; EE: YM2612 port 0 register
; ---------------------------------------------------------------------------
                bra.w   Sound_SelectFMInstrument        ; EF: FM instrument
; ---------------------------------------------------------------------------
                bra.w   Sound_ConfigureVibrato          ; F0: custom vibrato
; ---------------------------------------------------------------------------
                bra.w   Sound_SetChannelTypePitchEnvelope  ; F1: separate PSG/FM pitch envelopes
; ---------------------------------------------------------------------------
                bra.w   Sound_StopSequenceChannel       ; F2: stop track
; ---------------------------------------------------------------------------
                bra.w   Sound_SetPSGNoiseMode           ; F3: PSG noise
; ---------------------------------------------------------------------------
                bra.w   Sound_SetPitchEnvelope          ; F4: pitch envelope
; ---------------------------------------------------------------------------
                bra.w   Sound_SetPSGVolumeEnvelope      ; F5: PSG volume envelope
; ---------------------------------------------------------------------------
                bra.w   Sound_JumpSequenceRelative      ; F6: jump
; ---------------------------------------------------------------------------
                bra.w   Sound_RepeatSequenceBlock       ; F7: loop
; ---------------------------------------------------------------------------
                bra.w   Sound_CallRelativeSequenceSubroutine  ; F8: call sequence subroutine
; ---------------------------------------------------------------------------
                bra.w   Sound_ReturnFromSequenceSubroutine  ; F9: return
; ---------------------------------------------------------------------------
                bra.w   Sound_SetChannelTickMultiplier  ; FA: current tick multiplier
; ---------------------------------------------------------------------------
                bra.w   Sound_AddChannelTranspose       ; FB: transpose
; ---------------------------------------------------------------------------
                bra.w   Sound_EnableVibrato             ; FC: enable vibrato
; ---------------------------------------------------------------------------
                bra.w   Sound_DisableVibrato            ; FD: disable vibrato
; ---------------------------------------------------------------------------
                bra.w   Sound_SetFM3SpecialMode         ; FE: YM2612 channel 3 special mode
; End of function Sound_DispatchSequenceCommand
; Dispatch extended sequence commands following prefix $FF
Sound_DispatchExtendedSequenceCommand:
                moveq   #0,d0                           ; was: sub_838A6
                move.b  (a4)+,d0
                lsl.w   #2,d0
                jmp     Sound_ExtendedSequenceCommandJumpTable(pc,d0.w)
; ---------------------------------------------------------------------------
Sound_ExtendedSequenceCommandJumpTable:                 ; was: loc_838B0
                bra.w   Sound_ConfigureFMSSGEG          ; FF 00: SSG-EG setup
; ---------------------------------------------------------------------------
                bra.w   Sound_SetBGMPlaybackPaused      ; FF 01: pause/resume music
; ---------------------------------------------------------------------------
                bra.w   Sound_SetAllBGMChannelTickMultipliers  ; FF 02: all tick multipliers
; ---------------------------------------------------------------------------
                bra.w   Sound_RequestBGMVolumeAttenuation  ; FF 03: attenuate BGM
; ---------------------------------------------------------------------------
                bra.w   Sound_RequestBGMVolumeRestore   ; FF 04: restore BGM volume
; End of function Sound_DispatchExtendedSequenceCommand
; Replace the channel panning bits while preserving its stored AMS/FMS bits (E0)
Sound_SetSequencePanning:                               ; was: sub_838C4
                move.b  (a4)+,d1
                tst.b   1(a5)
                bmi.s   Sound_SetSequencePanningReturn
                move.b  $27(a5),d0
                andi.b  #$37,d0                         ; '7'
                or.b    d0,d1
                move.b  d1,$27(a5)
                jmp     Sound_WriteChannelPanAndAMS(pc)  ; (pc)
; ---------------------------------------------------------------------------
Sound_SetSequencePanningReturn:                         ; was: locret_838DE
                rts
; End of function Sound_SetSequencePanning
; Sets channel detune (E1)
Sound_SetChannelDetune:                                 ; was: sub_838E0
                move.b  (a4)+,$1E(a5)
                rts
; End of function Sound_SetChannelDetune
; Sets the global communication byte (E2)
Sound_SetCommunicationByte:                             ; was: sub_838E6
                move.b  (a4)+,(SoundCommunicationByte).w
                rts
; End of function Sound_SetCommunicationByte
; Silence the current FM operators before stopping its sequence channel (E3)
Sound_SilenceFMOperatorsAndStopChannel:                 ; was: sub_838EC
                jsr     Sound_SilenceCurrentFMOperators(pc)  ; (pc)
                bra.w   Sound_StopSequenceChannel
; End of function Sound_SilenceFMOperatorsAndStopChannel
; Configures or disables pan animation (E4)
Sound_SetPanAnimation:                                  ; was: sub_838F4
                move.b  (a4)+,$1F(a5)
                beq.s   Sound_DisablePanAnimationAndRestorePanning
                move.b  (a4)+,$20(a5)
                move.b  (a4)+,$21(a5)
                move.b  (a4)+,$22(a5)
                move.b  (a4),$23(a5)
                move.b  (a4)+,$24(a5)
                rts
; ---------------------------------------------------------------------------
Sound_DisablePanAnimationAndRestorePanning:             ; was: loc_83910
                move.b  $27(a5),d1
                jmp     Sound_WriteChannelPanAndAMS(pc)  ; (pc)
; End of function Sound_SetPanAnimation
; Adds separate PSG/FM volume offsets, selecting by channel type (E5)
Sound_AddChannelTypeVolumeOffset:                       ; was: sub_83918
                move.b  (a4)+,d0
                tst.b   1(a5)
                bpl.s   Sound_AddFMVolumeOffset
                add.b   d0,9(a5)
                addq.w  #1,a4
                rts
; ---------------------------------------------------------------------------
Sound_AddFMVolumeOffset:                                ; was: loc_83928
                                        ; Sound_AddChannelTypeVolumeOffset+6   j
                move.b  (a4)+,d0
                add.b   d0,9(a5)
                bra.w   Sound_ApplyFMVolumeOffset
; End of function Sound_AddChannelTypeVolumeOffset
; Holds the next note without retriggering it (E7)
Sound_HoldNextNote:                                     ; was: sub_83932
                bset    #4,(a5)
                rts
; End of function Sound_HoldNextNote
; Sets the note stop timeout (E8)
Sound_SetNoteStopTimeout:                               ; was: sub_83938
                move.b  (a4),$12(a5)
                move.b  (a4)+,$13(a5)
                rts
; End of function Sound_SetNoteStopTimeout
; Configure the YM2612 LFO, operator AM flags, and channel AMS/FMS bits (E9)
Sound_ConfigureFMLFOAndAmplitudeModulation:             ; was: sub_83942
                movea.l (SoundBGMDataPtr).w,a1
                beq.s   Sound_ConfigureFMOperatorAmplitudeModulation
                movea.l $20(a5),a1
Sound_ConfigureFMOperatorAmplitudeModulation:           ; was: loc_8394C
                move.b  (a4),d3
                adda.w  #9,a0
                lea     Sound_FMOperatorDecayAndAMRegisters(pc),a2
                moveq   #3,d6
Sound_ConfigureNextFMOperatorAmplitudeModulation:       ; was: loc_83958
                move.b  (a1)+,d1
                move.b  (a2)+,d0
                btst    #7,d3
                beq.s   Sound_AdvanceFMOperatorAmplitudeMask
                bset    #7,d1
                jsr     Sound_WriteCurrentFMRegisterIfNotOverridden(pc)  ; (pc)
Sound_AdvanceFMOperatorAmplitudeMask:                   ; was: loc_8396A
                lsl.w   #1,d3
                dbf     d6,Sound_ConfigureNextFMOperatorAmplitudeModulation
                move.b  (a4)+,d1
                moveq   #$22,d0                         ; '"'
                jsr     Sound_WriteYM2612Port0Thunk(pc)  ; (pc)
                move.b  (a4)+,d1
                move.b  $27(a5),d0
                andi.b  #$C0,d0
                or.b    d0,d1
                move.b  d1,$27(a5)
                jmp     Sound_WriteChannelPanAndAMS(pc)  ; (pc)
; End of function Sound_ConfigureFMLFOAndAmplitudeModulation
; ---------------------------------------------------------------------------
Sound_FMOperatorDecayAndAMRegisters:    dc.b    $60, $68, $64, $6C  ; was: byte_8398C

; Sets the music tempo and reload value (EA)
Sound_SetTempoReload:                                   ; was: sub_83990
                move.b  (a4),(SoundTempoReload).w
                move.b  (a4)+,(SoundTempoCounter).w
                rts
; End of function Sound_SetTempoReload
; Queues a sound ID from sequence data (EB)
Sound_QueueSequenceSoundRequest:                        ; was: sub_8399A
                move.b  (a4)+,(SoundRequestQueue).w
                rts
; End of function Sound_QueueSequenceSoundRequest
; Adds a PSG volume offset (EC)
Sound_AddPSGVolumeOffset:                               ; was: sub_839A0
                move.b  (a4)+,d0
                add.b   d0,9(a5)
                rts
; End of function Sound_AddPSGVolumeOffset
; Writes a register on the current FM channel (ED)
Sound_WriteCurrentFMRegisterFromSequence:               ; was: sub_839A8
                move.b  (a4)+,d0
                move.b  (a4)+,d1
                bra.w   Sound_WriteCurrentFMRegisterIfNotOverridden
; End of function Sound_WriteCurrentFMRegisterFromSequence
; Writes an address/data pair directly to YM2612 port 0 (EE)
Sound_WriteYM2612Port0RegisterFromSequence:             ; was: sub_839B0
                move.b  (a4)+,d0
                move.b  (a4)+,d1
                bra.w   Sound_WriteYM2612Port0Thunk
; End of function Sound_WriteYM2612Port0RegisterFromSequence
; Select and program the channel's FM instrument (EF)
Sound_SelectFMInstrument:                               ; was: sub_839B8
                moveq   #0,d0
                move.b  (a4)+,d0
                move.b  d0,$B(a5)
                btst    #2,(a5)
                bne.w   Sound_FMInstrumentUpdateReturn
                movea.l (SoundBGMDataPtr).w,a1
                tst.b   (SoundChannelGroupFlags).w
                beq.s   Sound_ProgramFMInstrument
                movea.l $20(a5),a1
                bmi.s   Sound_ProgramFMInstrument
                movea.l (SoundSpecialSFXDataPtr).w,a1
; End of function Sound_SelectFMInstrument
; Program the selected FM instrument and apply its current channel volume
Sound_ProgramFMInstrument:                              ; was: sub_839DC
                                        ; Sound_StopSpecialSFXAndRestoreBGMChannels+2E   p
                subq.w  #1,d0
                bmi.s   Sound_LoadFMInstrumentParameters
                move.w  #$19,d1
Sound_AdvanceToSelectedFMInstrument:                    ; was: loc_839E4
                adda.w  d1,a1
                dbf     d0,Sound_AdvanceToSelectedFMInstrument
Sound_LoadFMInstrumentParameters:                       ; was: loc_839EA
                move.b  (a1)+,d1
                move.b  d1,$25(a5)
                move.b  d1,d4
                move.b  #$B0,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                lea     Sound_FMInstrumentParameterRegisters(pc),a2
                moveq   #$13,d3
Sound_WriteNextFMInstrumentParameter:                   ; was: loc_83A00
                move.b  (a2)+,d0
                move.b  (a1)+,d1
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                dbf     d3,Sound_WriteNextFMInstrumentParameter
                moveq   #3,d5
                andi.w  #7,d4
                move.b  Sound_FMAlgorithmCarrierMasks(pc,d4.w),d4
                move.b  9(a5),d3
Sound_WriteNextFMOperatorLevel:                         ; was: loc_83A1A
                move.b  (a2)+,d0
                move.b  (a1)+,d1
                lsr.b   #1,d4
                bcc.s   Sound_WriteFMOperatorLevel
                add.b   d3,d1
Sound_WriteFMOperatorLevel:                             ; was: loc_83A24
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                dbf     d5,Sound_WriteNextFMOperatorLevel
                cmpi.b  #6,1(a5)
                bne.w   Sound_WriteStoredFMChannelPanning
                cmpa.l  #$40,a5                         ; '@'
                beq.w   Sound_FMInstrumentUpdateReturn
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusToShareDACChannelPanning:            ; was: loc_83A4E
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusToShareDACChannelPanning
                move.b  (Z80DACRequestState).l,d0
                beq.w   Sound_ReleaseZ80BusAfterDACChannelPanning
                move.b  $27(a5),(Z80DACPanningUpdate).l
Sound_ReleaseZ80BusAfterDACChannelPanning:              ; was: loc_83A6A
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                tst.b   d0
                bne.s   Sound_FMInstrumentUpdateReturn
; Write the stored channel panning/AMS/FMS byte to YM2612 register B4
Sound_WriteStoredFMChannelPanning:                      ; was: loc_83A78
                move.b  $27(a5),d1
                move.b  #$B4,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
Sound_FMInstrumentUpdateReturn:                         ; was: locret_83A84
                                        ; Sound_ProgramFMInstrument+60   j
                rts
; End of function Sound_ProgramFMInstrument
; ---------------------------------------------------------------------------
Sound_FMAlgorithmCarrierMasks:  dc.b    8, 8, 8, 8, $A, $E, $E, $F  ; was: byte_83A86
                                        ; Sound_ApplyFMVolumeOffset+42   r

; Apply the channel volume offset to the carrier operators of its FM instrument
Sound_ApplyFMVolumeOffset:                              ; was: sub_83A8E
                                        ; Sound_UpdateBGMVolumeTransitions+EE   p
                btst    #2,(a5)
                bne.s   Sound_ApplyFMVolumeOffsetReturn
                moveq   #0,d0
                move.b  $B(a5),d0
                movea.l (SoundBGMDataPtr).w,a1
                tst.b   (SoundChannelGroupFlags).w
                beq.s   Sound_SelectFMInstrumentForVolumeUpdate
                movea.l $20(a5),a1
                tst.b   (SoundChannelGroupFlags).w
                bmi.s   Sound_SelectFMInstrumentForVolumeUpdate
                movea.l (SoundSpecialSFXDataPtr).w,a1
Sound_SelectFMInstrumentForVolumeUpdate:                ; was: loc_83AB2
                                        ; Sound_ApplyFMVolumeOffset+1E   j
                subq.w  #1,d0
                bmi.s   Sound_SelectFMOperatorLevelParameters
                move.w  #$19,d1
Sound_AdvanceToCurrentFMInstrument:                     ; was: loc_83ABA
                adda.w  d1,a1
                dbf     d0,Sound_AdvanceToCurrentFMInstrument
Sound_SelectFMOperatorLevelParameters:                  ; was: loc_83AC0
                adda.w  #$15,a1
                lea     Sound_FMOperatorLevelRegisters(pc),a2
                move.b  $25(a5),d0
                andi.w  #7,d0
                move.b  Sound_FMAlgorithmCarrierMasks(pc,d0.w),d4
                move.b  9(a5),d3
                bmi.s   Sound_ApplyFMVolumeOffsetReturn
                moveq   #3,d5
Sound_ApplyNextFMOperatorLevel:                         ; was: loc_83ADC
                move.b  (a2)+,d0
                move.b  (a1)+,d1
                lsr.b   #1,d4
                bcc.s   Sound_ContinueFMOperatorLevelLoop
                add.b   d3,d1
                bcs.s   Sound_ContinueFMOperatorLevelLoop
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
Sound_ContinueFMOperatorLevelLoop:                      ; was: loc_83AEC
                                        ; Sound_ApplyFMVolumeOffset+58   j
                dbf     d5,Sound_ApplyNextFMOperatorLevel
Sound_ApplyFMVolumeOffsetReturn:                        ; was: locret_83AF0
                                        ; Sound_ApplyFMVolumeOffset+4A   j
                rts
; End of function Sound_ApplyFMVolumeOffset
; ---------------------------------------------------------------------------
Sound_FMInstrumentParameterRegisters:   dc.b    $30, $38, $34, $3C, $50, $58, $54, $5C, $60, $68, $64, $6C, $70, $78, $74, $7C  ; was: byte_83AF2
                dc.b    $80, $88, $84, $8C
Sound_FMOperatorLevelRegisters: dc.b    $40, $48, $44, $4C  ; was: byte_83B06
