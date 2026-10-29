; Apply manual BGM volume steps and voice-DAC ducking transitions
Sound_UpdateBGMVolumeTransitions:                       ; was: sub_836A0
                cmpi.b  #2,(SoundVoiceDuckingState).w
                beq.w   Sound_CheckVoiceDACDuckingState
                move.b  (SoundManualVolumeState).w,d0
                beq.w   Sound_CheckVoiceDACDuckingState
                bmi.w   Sound_HandleManualVolumeRestoreRequest
                cmpi.b  #1,d0
                bne.w   Sound_CheckVoiceDACDuckingState
                move.b  #2,(SoundManualVolumeState).w
                bra.w   Sound_AttenuateBGMChannels
; ---------------------------------------------------------------------------
Sound_HandleManualVolumeRestoreRequest:                 ; was: loc_836C8
                move.b  #0,(SoundManualVolumeState).w
                bra.w   Sound_RestoreBGMChannelVolumes
; ---------------------------------------------------------------------------
Sound_CheckVoiceDACDuckingState:                        ; was: loc_836D2
                                        ; Sound_UpdateBGMVolumeTransitions+E   j
                cmpi.b  #2,(SoundManualVolumeState).w
                beq.w   Sound_UpdateBGMVolumeTransitionsReturn
                move.b  (SoundVoiceDuckingState).w,d0
                beq.w   Sound_UpdateBGMVolumeTransitionsReturn
                cmpi.b  #1,d0
                bne.w   Sound_CheckVoiceDACDuckingRelease
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForVoiceDACStartStatusZ80Bus:                 ; was: loc_836FA
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForVoiceDACStartStatusZ80Bus
                move.b  (Z80DACStatus).l,d7
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                btst    #5,d7
                beq.w   Sound_UpdateBGMVolumeTransitionsReturn
                move.b  #2,(SoundVoiceDuckingState).w
                move.b  (SoundFMVolumeStep).w,d0
                or.b    (SoundPSGVolumeStep).w,d0
                bne.w   Sound_AttenuateBGMChannels
                move.b  #$A,(SoundFMVolumeStep).w
                move.b  #2,(SoundPSGVolumeStep).w
                bra.w   Sound_AttenuateBGMChannels
; ---------------------------------------------------------------------------
Sound_CheckVoiceDACDuckingRelease:                      ; was: loc_8373E
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForVoiceDACEndStatusZ80Bus:                   ; was: loc_8374C
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForVoiceDACEndStatusZ80Bus
                move.b  (Z80DACStatus).l,d7
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                btst    #5,d7
                bne.w   Sound_UpdateBGMVolumeTransitionsReturn
                move.b  #0,(SoundVoiceDuckingState).w
                bra.w   Sound_RestoreBGMChannelVolumes
; ---------------------------------------------------------------------------
Sound_UpdateBGMVolumeTransitionsReturn:                 ; was: locret_83778
                                        ; Sound_UpdateBGMVolumeTransitions+40   j
                rts
; ---------------------------------------------------------------------------
Sound_AttenuateBGMChannels:                             ; was: loc_8377A
                                        ; Sound_UpdateBGMVolumeTransitions+8A   j
                move.b  (SoundFMVolumeStep).w,d6
                lea     (SoundBGMFMChannels).w,a5
                moveq   #5,d7
Sound_AttenuateNextBGMFMChannel:                        ; was: loc_83784
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMFMAttenuationLoop
                add.b   d6,9(a5)
                bmi.s   Sound_ContinueBGMFMAttenuationLoop
                jsr     Sound_ApplyFMVolumeOffset(pc)   ; (pc)
Sound_ContinueBGMFMAttenuationLoop:                     ; was: loc_83792
                                        ; Sound_UpdateBGMVolumeTransitions+EC   j
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_AttenuateNextBGMFMChannel
                move.b  (SoundPSGVolumeStep).w,d5
                moveq   #2,d7
Sound_AttenuateNextBGMPSGChannel:                       ; was: loc_837A0
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMPSGAttenuationLoop
                add.b   d5,9(a5)
                cmpi.b  #$10,9(a5)
                bcc.s   Sound_ContinueBGMPSGAttenuationLoop
                move.b  9(a5),d6
                jsr     Sound_ApplyPSGVolume(pc)        ; (pc)
Sound_ContinueBGMPSGAttenuationLoop:                    ; was: loc_837B8
                                        ; Sound_UpdateBGMVolumeTransitions+10E   j
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_AttenuateNextBGMPSGChannel
                rts
; ---------------------------------------------------------------------------
Sound_RestoreBGMChannelVolumes:                         ; was: loc_837C2
                                        ; Sound_UpdateBGMVolumeTransitions+D4   j
                move.b  (SoundFMVolumeStep).w,d6
                lea     (SoundBGMFMChannels).w,a5
                moveq   #5,d7
Sound_RestoreNextBGMFMChannelVolume:                    ; was: loc_837CC
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMFMVolumeRestoreLoop
                sub.b   d6,9(a5)
                jsr     Sound_ApplyFMVolumeOffset(pc)   ; (pc)
Sound_ContinueBGMFMVolumeRestoreLoop:                   ; was: loc_837D8
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_RestoreNextBGMFMChannelVolume
                move.b  (SoundPSGVolumeStep).w,d5
                moveq   #2,d7
Sound_RestoreNextBGMPSGChannelVolume:                   ; was: loc_837E6
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMPSGVolumeRestoreLoop
                sub.b   d5,9(a5)
                move.b  9(a5),d6
                jsr     Sound_ApplyPSGVolume(pc)        ; (pc)
Sound_ContinueBGMPSGVolumeRestoreLoop:                  ; was: loc_837F6
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_RestoreNextBGMPSGChannelVolume
                clr.b   (SoundFMVolumeStep).w
                clr.b   (SoundPSGVolumeStep).w
                rts
; End of function Sound_UpdateBGMVolumeTransitions
; ---------------------------------------------------------------------------
Sound_FMNoteFrequencyTable: dc.w    $25E, $284, $2AB, $2D3, $2FE, $32D, $35C, $38F, $3C5, $3FF, $43C, $47C  ; was: word_83808
