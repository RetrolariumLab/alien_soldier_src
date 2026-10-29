; Sequence channel, control-flow, and extended command handlers
; Configure the channel's custom vibrato parameters (F0)
Sound_ConfigureVibrato:                                 ; was: sub_83B0A
                bset    #7,$A(a5)
                move.l  a4,$14(a5)
                move.b  (a4)+,$18(a5)
                move.b  (a4)+,$19(a5)
                move.b  (a4)+,$1A(a5)
                move.b  (a4)+,d0
                lsr.b   #1,d0
                move.b  d0,$1B(a5)
                clr.w   $1C(a5)
                rts
; End of function Sound_ConfigureVibrato
; Select separate PSG/FM pitch-envelope IDs by channel type (F1)
Sound_SetChannelTypePitchEnvelope:                      ; was: sub_83B2E
                move.b  (a4)+,d0
                tst.b   1(a5)
                bpl.w   Sound_SetPitchEnvelope
                move.b  d0,$A(a5)
                move.b  (a4)+,d0
                rts
; End of function Sound_SetChannelTypePitchEnvelope
; Stop the current sequence channel and restore any BGM channel it overrode (F2)
Sound_StopSequenceChannel:                              ; was: sub_83B40
                                        ; Sound_SilenceFMOperatorsAndStopChannel+4   j
                bclr    #7,(a5)
                bclr    #4,(a5)
                tst.b   1(a5)
                bmi.s   Sound_MuteStoppedPSGChannel
                tst.b   (SoundPCMEventFlag).w
                bmi.w   Sound_ExitStoppedSequenceChannel
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
                bra.s   Sound_CheckStoppedSFXChannelRestore
; ---------------------------------------------------------------------------
Sound_MuteStoppedPSGChannel:                            ; was: loc_83B5C
                jsr     Sound_MutePSGIfNotOverridden(pc)  ; (pc)
Sound_CheckStoppedSFXChannelRestore:                    ; was: loc_83B60
                tst.b   (SoundChannelGroupFlags).w
                bpl.w   Sound_ExitStoppedSequenceChannel
                clr.b   (SoundCurrentPriority).w
                moveq   #0,d0
                move.b  1(a5),d0
                bmi.s   Sound_SelectStoppedSequenceBGMPSGChannel
                lea     Sound_BGMChannelRecordPointers(pc),a0
                movea.l a5,a3
                cmpi.b  #4,d0
                bne.s   Sound_SelectStoppedSequenceBGMFMChannel
                tst.b   (SoundSpecialSFXFM).w
                bpl.s   Sound_SelectStoppedSequenceBGMFMChannel
                lea     (SoundSpecialSFXFM).w,a5
                movea.l (SoundSpecialSFXDataPtr).w,a1
                bra.s   Sound_RestoreStoppedSequenceBGMFMChannel
; ---------------------------------------------------------------------------
Sound_SelectStoppedSequenceBGMFMChannel:                ; was: loc_83B90
                                        ; Sound_StopSequenceChannel+44   j
                subq.b  #2,d0
                lsl.b   #2,d0
                movea.l (a0,d0.w),a5
                tst.b   (a5)
                bpl.s   Sound_CheckStoppedFM3SpecialMode
                movea.l (SoundBGMDataPtr).w,a1
Sound_RestoreStoppedSequenceBGMFMChannel:               ; was: loc_83BA0
                bclr    #2,(a5)
                bset    #1,(a5)
                move.b  $B(a5),d0
                jsr     Sound_ProgramFMInstrument(pc)   ; (pc)
Sound_CheckStoppedFM3SpecialMode:                       ; was: loc_83BB0
                movea.l a3,a5
                cmpi.b  #2,1(a5)
                bne.s   Sound_ExitStoppedSequenceChannel
                tst.b   (SoundFM3SpecialMode).w
                bne.s   Sound_ExitStoppedSequenceChannel
                moveq   #0,d1
                moveq   #$27,d0                         ; '''
                jsr     Sound_WriteYM2612Port0Thunk(pc)  ; (pc)
                bra.s   Sound_ExitStoppedSequenceChannel
; ---------------------------------------------------------------------------
Sound_SelectStoppedSequenceBGMPSGChannel:               ; was: loc_83BCA
                lea     (SoundSpecialSFXPSG).w,a0
                tst.b   (a0)
                bpl.s   Sound_MapStoppedSequenceBGMPSGChannel
                cmpi.b  #$E0,d0
                beq.s   Sound_RestoreStoppedSequenceBGMPSGChannel
                cmpi.b  #$C0,d0
                beq.s   Sound_RestoreStoppedSequenceBGMPSGChannel
Sound_MapStoppedSequenceBGMPSGChannel:                  ; was: loc_83BDE
                lea     Sound_BGMChannelRecordPointers(pc),a0
                lsr.b   #3,d0
                movea.l (a0,d0.w),a0
Sound_RestoreStoppedSequenceBGMPSGChannel:              ; was: loc_83BE8
                                        ; Sound_StopSequenceChannel+9C   j
                bclr    #2,(a0)
                bset    #1,(a0)
                cmpi.b  #$E0,1(a0)
                bne.s   Sound_ExitStoppedSequenceChannel
                move.b  $25(a0),(VDP_PSG).l
Sound_ExitStoppedSequenceChannel:                       ; was: loc_83C00
                                        ; Sound_StopSequenceChannel+24   j
                addq.w  #8,sp
                rts
; End of function Sound_StopSequenceChannel
; Selects PSG noise mode and writes the PSG control byte (F3)
Sound_SetPSGNoiseMode:                                  ; was: sub_83C04
                move.b  #$E0,1(a5)
                move.b  (a4)+,$25(a5)
                btst    #2,(a5)
                bne.s   Sound_SetPSGNoiseModeReturn
                move.b  -1(a4),(VDP_PSG).l
Sound_SetPSGNoiseModeReturn:                            ; was: locret_83C1C
                rts
; End of function Sound_SetPSGNoiseMode
; Select a pitch-envelope ID common to all channel types (F4)
Sound_SetPitchEnvelope:                                 ; was: sub_83C1E
                                        ; Sound_SetChannelTypePitchEnvelope+6   j
                move.b  (a4)+,$A(a5)
                rts
; End of function Sound_SetPitchEnvelope
; Select a PSG volume-envelope ID (F5)
Sound_SetPSGVolumeEnvelope:                             ; was: sub_83C24
                move.b  (a4)+,$B(a5)
                rts
; End of function Sound_SetPSGVolumeEnvelope
; Jumps relative offset in track data
Sound_JumpSequenceRelative:                             ; was: sub_83C2A
                                        ; Sound_RepeatSequenceBlock+14   j
                move.b  (a4)+,d0
                lsl.w   #8,d0
                move.b  (a4)+,d0
                adda.w  d0,a4
                subq.w  #1,a4
                rts
; End of function Sound_JumpSequenceRelative
; Loop counter with conditional jump
Sound_RepeatSequenceBlock:                              ; was: sub_83C36
                moveq   #0,d0
                move.b  (a4)+,d0
                move.b  (a4)+,d1
                tst.b   $28(a5,d0.w)
                bne.s   Sound_DecrementSequenceLoopCounter
                move.b  d1,$28(a5,d0.w)
Sound_DecrementSequenceLoopCounter:                     ; was: loc_83C46
                subq.b  #1,$28(a5,d0.w)
                bne.s   Sound_JumpSequenceRelative
                addq.w  #2,a4
                rts
; End of function Sound_RepeatSequenceBlock
; Calls a relative sequence subroutine (F8)
Sound_CallRelativeSequenceSubroutine:                   ; was: sub_83C50
                moveq   #0,d0
                move.b  $D(a5),d0
                subq.b  #4,d0
                move.l  a4,(a5,d0.w)
                move.b  d0,$D(a5)
                bra.s   Sound_JumpSequenceRelative
; End of function Sound_CallRelativeSequenceSubroutine
; Returns from a sequence subroutine (F9)
Sound_ReturnFromSequenceSubroutine:                     ; was: sub_83C62
                moveq   #0,d0
                move.b  $D(a5),d0
                movea.l (a5,d0.w),a4
                addq.w  #2,a4
                addq.b  #4,d0
                move.b  d0,$D(a5)
                rts
; End of function Sound_ReturnFromSequenceSubroutine
; Sets the current channel tick multiplier (FA)
Sound_SetChannelTickMultiplier:                         ; was: sub_83C76
                move.b  (a4)+,2(a5)
                rts
; End of function Sound_SetChannelTickMultiplier
; Adds transpose value to sound channel pitch offset
Sound_AddChannelTranspose:                              ; was: sub_83C7C
                move.b  (a4)+,d0
                add.b   d0,8(a5)
                rts
; End of function Sound_AddChannelTranspose
; Enable the custom vibrato state stored in the channel record (FC)
Sound_EnableVibrato:                                    ; was: sub_83C84
                bset    #7,$A(a5)
                rts
; End of function Sound_EnableVibrato
; Disable the channel's custom vibrato state (FD)
Sound_DisableVibrato:                                   ; was: sub_83C8C
                bclr    #7,$A(a5)
                rts
; End of function Sound_DisableVibrato
; Configures YM2612 CH3 special mode with frequency values for each operator
Sound_SetFM3SpecialMode:                                ; was: sub_83C94
                lea     (SoundSFXFM3Offsets).w,a0
                tst.b   (SoundChannelGroupFlags).w
                bne.s   Sound_SelectFM3SpecialFrequencyOffsetSlots
                lea     (SoundBGMFM3Offsets).w,a0
                move.b  #$80,(SoundFM3SpecialMode).w
Sound_SelectFM3SpecialFrequencyOffsetSlots:             ; was: loc_83CA8
                moveq   #3,d0
Sound_SetNextFM3SpecialFrequencyOffset:                 ; was: loc_83CAA
                moveq   #0,d1
                move.b  (a4)+,d1
                lsl.w   #1,d1
                move.w  Sound_FM3SpecialFrequencyOffsetTable(pc,d1.w),(a0)+
                dbf     d0,Sound_SetNextFM3SpecialFrequencyOffset
                move.b  #$27,d0                         ; '''
                moveq   #$40,d1                         ; '@'
                bra.w   Sound_WriteYM2612Port0Thunk
; End of function Sound_SetFM3SpecialMode
; ---------------------------------------------------------------------------
Sound_FM3SpecialFrequencyOffsetTable:   dc.w    0, $180, $1F4, $260  ; was: word_83CC2

; Configures SSG-EG and forces full attack for all four FM operators (FF 00)
Sound_ConfigureFMSSGEG:                                 ; was: sub_83CCA
                lea     Sound_FMOperatorSSGEGAndAttackRateRegisters(pc),a1
                moveq   #3,d3
Sound_ConfigureNextFMOperatorSSGEG:                     ; was: loc_83CD0
                move.b  (a1)+,d0
                move.b  (a4)+,d1
                jsr     Sound_WriteCurrentFMRegisterIfNotOverridden(pc)  ; (pc)
                move.b  (a1)+,d0
                moveq   #$1F,d1
                jsr     Sound_WriteCurrentFMRegisterIfNotOverridden(pc)  ; (pc)
                dbf     d3,Sound_ConfigureNextFMOperatorSSGEG
                rts
; End of function Sound_ConfigureFMSSGEG
; ---------------------------------------------------------------------------
Sound_FMOperatorSSGEGAndAttackRateRegisters:    dc.b    $90, $50, $98, $58, $94, $54, $9C, $5C  ; was: byte_83CE6

; Pause or resume the ten BGM playback records (FF 01)
Sound_SetBGMPlaybackPaused:                             ; was: sub_83CEE
                moveq   #$30,d3                         ; '0'
                move.b  (a4)+,d0
                beq.s   Sound_ResumeBGMPlayback
                movea.l a5,a3
                lea     (SoundPCMChannelRecord).w,a5
                btst    #7,(a5)
                beq.s   Sound_PrepareBGMFMPauseLoop
                bclr    #7,(a5)
                bset    #0,(a5)
Sound_PrepareBGMFMPauseLoop:                            ; was: loc_83D08
                moveq   #5,d4
Sound_PauseNextBGMFMChannel:                            ; was: loc_83D0A
                adda.w  d3,a5
                btst    #7,(a5)
                beq.s   Sound_ContinueBGMFMPauseLoop
                bclr    #7,(a5)
                bset    #0,(a5)
                move.b  #$B4,d0
                moveq   #0,d1
                jsr     Sound_WriteCurrentFMRegisterIfNotOverridden(pc)  ; (pc)
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
Sound_ContinueBGMFMPauseLoop:                           ; was: loc_83D28
                dbf     d4,Sound_PauseNextBGMFMChannel
                moveq   #2,d4
Sound_PauseNextBGMPSGChannel:                           ; was: loc_83D2E
                adda.w  d3,a5
                btst    #7,(a5)
                beq.s   Sound_ContinueBGMPSGPauseLoop
                bclr    #7,(a5)
                bset    #0,(a5)
                jsr     Sound_MutePSGIfNotOverridden(pc)  ; (pc)
Sound_ContinueBGMPSGPauseLoop:                          ; was: loc_83D42
                dbf     d4,Sound_PauseNextBGMPSGChannel
                movea.l a3,a5
                rts
; ---------------------------------------------------------------------------
Sound_ResumeBGMPlayback:                                ; was: loc_83D4A
                movea.l a5,a3
                lea     (SoundPCMChannelRecord).w,a5
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusToReadDACPanning:                    ; was: loc_83D5E
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusToReadDACPanning
                move.b  (Z80DACRequestState).l,d0
                move.b  (Z80DACPanning).l,d1
                move.b  (Z80DACCommandByte6).l,d2
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                tst.b   d0
                beq.w   Sound_ResumeBGMPCMChannel
                bpl.w   Sound_RestoreActiveDACPanning
                move.b  d2,d1
Sound_RestoreActiveDACPanning:                          ; was: loc_83D90
                move.b  #$B6,d0
                jsr     Sound_WriteYM2612Port1(pc)      ; (pc)
Sound_ResumeBGMPCMChannel:                              ; was: loc_83D98
                btst    #0,(a5)
                beq.s   Sound_PrepareBGMFMResumeLoop
                bset    #7,(a5)
                bclr    #0,(a5)
Sound_PrepareBGMFMResumeLoop:                           ; was: loc_83DA6
                moveq   #5,d4
Sound_ResumeNextBGMFMChannel:                           ; was: loc_83DA8
                adda.w  d3,a5
                btst    #0,(a5)
                beq.s   Sound_ContinueBGMFMResumeLoop
                bset    #7,(a5)
                bclr    #0,(a5)
                btst    #2,(a5)
                bne.s   Sound_ContinueBGMFMResumeLoop
                move.b  $27(a5),d1
                cmpi.b  #6,1(a5)
                bne.w   Sound_RestoreBGMFMChannelPanning
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusBeforeFM6PanningRestore:             ; was: loc_83DDA
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusBeforeFM6PanningRestore
                move.b  (Z80DACRequestState).l,d0
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                tst.b   d0
                bne.w   Sound_ContinueBGMFMResumeLoop
Sound_RestoreBGMFMChannelPanning:                       ; was: loc_83DFA
                move.b  #$B4,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
Sound_ContinueBGMFMResumeLoop:                          ; was: loc_83E02
                                        ; Sound_SetBGMPlaybackPaused+CE   j
                dbf     d4,Sound_ResumeNextBGMFMChannel
                moveq   #2,d4
Sound_ResumeNextBGMPSGChannel:                          ; was: loc_83E08
                adda.w  d3,a5
                btst    #0,(a5)
                beq.s   Sound_ContinueBGMPSGResumeLoop
                bset    #7,(a5)
                bclr    #0,(a5)
Sound_ContinueBGMPSGResumeLoop:                         ; was: loc_83E18
                dbf     d4,Sound_ResumeNextBGMPSGChannel
                movea.l a3,a5
                rts
; End of function Sound_SetBGMPlaybackPaused
; Sets the tick multiplier for all ten sound channels (FF 02)
Sound_SetAllBGMChannelTickMultipliers:                  ; was: sub_83E20
                lea     (SoundPCMChannelRecord).w,a0
                move.b  (a4)+,d0
                moveq   #$30,d1                         ; '0'
                moveq   #9,d2
Sound_SetNextBGMChannelTickMultiplier:                  ; was: loc_83E2A
                move.b  d0,2(a0)
                adda.w  d1,a0
                dbf     d2,Sound_SetNextBGMChannelTickMultiplier
                rts
; End of function Sound_SetAllBGMChannelTickMultipliers
; Request one BGM attenuation step, installing its FM/PSG amounts if idle (FF 03)
Sound_RequestBGMVolumeAttenuation:                      ; was: sub_83E36
                tst.b   (SoundManualVolumeState).w
                beq.w   Sound_StartBGMVolumeAttenuationRequest
                addq.w  #2,a4
                rts
; ---------------------------------------------------------------------------
Sound_StartBGMVolumeAttenuationRequest:                 ; was: loc_83E42
                move.b  #1,(SoundManualVolumeState).w
                move.b  (SoundFMVolumeStep).w,d0
                or.b    (SoundPSGVolumeStep).w,d0
                bne.w   Sound_RequestBGMVolumeAttenuationReturn
                move.b  (a4)+,(SoundFMVolumeStep).w
                move.b  (a4)+,(SoundPSGVolumeStep).w
Sound_RequestBGMVolumeAttenuationReturn:                ; was: locret_83E5C
                rts
; End of function Sound_RequestBGMVolumeAttenuation
; Request restoration after the pending BGM attenuation has been applied (FF 04)
Sound_RequestBGMVolumeRestore:                          ; was: sub_83E5E
                cmpi.b  #2,(SoundManualVolumeState).w
                bne.w   Sound_RequestBGMVolumeRestoreReturn
                move.b  #$80,(SoundManualVolumeState).w
Sound_RequestBGMVolumeRestoreReturn:                    ; was: locret_83E6E
                rts
; End of function Sound_RequestBGMVolumeRestore
; ---------------------------------------------------------------------------
