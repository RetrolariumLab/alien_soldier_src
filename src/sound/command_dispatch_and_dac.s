Sound_SelectPendingRequest:                             ; was: sub_829AA
                lea     Sound_RequestPriorityTable(pc),a0
                lea     (SoundChannelGroupFlags).w,a1
                move.b  (SoundCurrentPriority).w,d3
                moveq   #3,d4
Sound_ScanNextPendingRequestSlot:                       ; was: loc_829B8
                move.b  -(a1),d0
                move.b  d0,d1
                clr.b   (a1)
                subq.b  #1,d0
                bcs.s   Sound_ContinuePendingRequestScan
                andi.w  #$FF,d0
                move.b  (a0,d0.w),d2
                cmpi.b  #$FF,d2
                beq.w   Sound_SelectPriorityBypassRequest
                move.b  d2,d5
                andi.b  #$7F,d5
                move.b  d3,d6
                andi.b  #$7F,d6
                cmp.b   d6,d5
                bcs.s   Sound_ContinuePendingRequestScan
                move.b  d2,d3
                move.b  d1,(SoundSelectedRequest).w
Sound_ContinuePendingRequestScan:                       ; was: loc_829E8
                                        ; Sound_SelectPendingRequest+36   j
                dbf     d4,Sound_ScanNextPendingRequestSlot
                tst.b   d3
                bmi.s   Sound_SelectPendingRequestReturn
                move.b  d3,(SoundCurrentPriority).w
Sound_SelectPendingRequestReturn:                       ; was: locret_829F4
                rts
; ---------------------------------------------------------------------------
Sound_SelectPriorityBypassRequest:                      ; was: loc_829F6
                move.b  d1,(SoundSelectedRequest).w
                bra.s   Sound_ContinuePendingRequestClearLoop
; ---------------------------------------------------------------------------
Sound_ClearNextPendingRequestSlot:                      ; was: loc_829FC
                move.b  -(a1),d0
                subq.b  #1,d0
                bcs.s   Sound_ClearCurrentPendingRequestSlot
                andi.w  #$FF,d0
                move.b  (a0,d0.w),d2
                cmpi.b  #$FF,d2
                beq.w   Sound_ContinuePendingRequestClearLoop
Sound_ClearCurrentPendingRequestSlot:                   ; was: loc_82A12
                clr.b   (a1)
Sound_ContinuePendingRequestClearLoop:                  ; was: loc_82A14
                                        ; Sound_SelectPendingRequest+64   j
                dbf     d4,Sound_ClearNextPendingRequestSlot
                rts
; End of function Sound_SelectPendingRequest
; Dispatch the selected driver-control, DAC, music, or SFX request by ID range
Sound_DispatchPendingRequest:                           ; was: sub_82A1A
                moveq   #0,d7
                move.b  (SoundSelectedRequest).w,d7
                move.b  #$FF,(SoundSelectedRequest).w
                tst.b   d7
                beq.w   Sound_LoadZ80Driver
                cmpi.b  #$FF,d7
                beq.s   Sound_DispatchPendingRequestReturn
                cmpi.b  #1,d7
                bcs.w   Sound_StopAllPlayback
                cmpi.b  #$10,d7
                bcs.w   Sound_ValidateControlRequest
                cmpi.b  #$40,d7                         ; '@'
                bcs.w   Sound_ValidateVoiceDACRequest
                cmpi.b  #$81,d7
                bcs.w   Sound_LoadSFX
                cmpi.b  #$A0,d7
                bcs.w   Sound_LoadBGMRequest
                cmpi.b  #$F9,d7
                bcs.w   Sound_ValidateHighRangeSFXRequest
                cmpi.b  #$FD,d7
                bcs.w   Sound_LoadSpecialSFX
Sound_DispatchPendingRequestReturn:                     ; was: locret_82A6A
                rts
; ---------------------------------------------------------------------------
Sound_ValidateControlRequest:                           ; was: loc_82A6C
                cmpi.b  #5,d7
                bcs.w   Sound_DispatchControlRequest
                rts
; ---------------------------------------------------------------------------
Sound_DispatchControlRequest:                           ; was: loc_82A76
                subq.b  #1,d7
                lsl.w   #2,d7
                jmp     Sound_ControlRequestBranches(pc,d7.w)
; ---------------------------------------------------------------------------
Sound_ControlRequestBranches:                           ; was: loc_82A7E
                bra.w   Sound_StartMusicFadeOut
; ---------------------------------------------------------------------------
                bra.w   Sound_StopSFXAndRestoreBGMChannels
; ---------------------------------------------------------------------------
                bra.w   Sound_StopSpecialSFXAndRestoreBGMChannels
; ---------------------------------------------------------------------------
                bra.w   Sound_StopAllPlayback
; ---------------------------------------------------------------------------
Sound_ValidateVoiceDACRequest:                          ; was: loc_82A8E
                cmpi.b  #$3F,d7                         ; '?'
                bcs.w   Sound_ProcessVoiceDACRequest
                rts
; ---------------------------------------------------------------------------
Sound_ProcessVoiceDACRequest:                           ; was: loc_82A98
                subi.b  #$10,d7
                ext.w   d7
                asl.w   #3,d7
                lea     (Sound_VoiceDACDescriptors).l,a0  ; 980 - Sound_PCMBank1
                                        ; A00 - Sound_PCMBank2
                                        ; A80 - Sound_PCMBank3
                                        ; B00 - Sound_PCMBank4
                                        ; B80 - Sound_PCMBank5
                                        ; C00 - Sound_PCMBank6
                                        ; C80 - Sound_PCMBank7
                                        ; D00 - Sound_PCMBank8
                                        ; D80 - Sound_PCMBank9
                lea     (a0,d7.w),a0
                btst    #0,5(a0)
                bne.w   Sound_SelectVoiceDACPlaybackSlot
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForVoiceDACStatusZ80Bus:                      ; was: loc_82AC2
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForVoiceDACStatusZ80Bus
                move.b  (Z80DACStatus).l,d1
                move.b  (Z80VoiceSlotAFlags).l,d2
                move.b  (Z80VoiceSlotBFlags).l,d3
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                move.b  d1,d6
                move.b  5(a0),d0
                andi.b  #$C0,d0
                btst    #0,d1
                bne.w   Sound_CompareActiveVoiceDACSlots
                andi.b  #$C0,d1
                cmp.b   d1,d0
                bcc.w   Sound_SubmitImmediateVoiceDACRequest
                rts
; ---------------------------------------------------------------------------
Sound_CompareActiveVoiceDACSlots:                       ; was: loc_82B06
                andi.b  #$C0,d2
                andi.b  #$C0,d3
                cmp.b   d2,d0
                bcs.w   Sound_ProcessVoiceDACRequestReturn
                cmp.b   d3,d0
                bcc.w   Sound_SubmitImmediateVoiceDACRequest
                rts
; ---------------------------------------------------------------------------
Sound_SubmitImmediateVoiceDACRequest:                   ; was: loc_82B1C
                                        ; Sound_DispatchPendingRequest+FC   j
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForImmediateVoiceDACZ80Bus:                   ; was: loc_82B2A
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForImmediateVoiceDACZ80Bus
                move.b  #$80,(Z80DACRequestState).l
                move.b  0.w(a0),(Z80DACCommandByte0).l
                move.b  1(a0),(Z80DACCommandByte1).l
                move.b  2(a0),(Z80DACCommandByte2).l
                move.b  3(a0),(Z80DACCommandByte3).l
                move.b  4(a0),(Z80DACCommandByte4).l
                move.b  5(a0),(Z80DACCommandByte5).l
                move.b  6(a0),(Z80DACCommandByte6).l
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                btst    #5,5(a0)
                beq.w   Sound_ProcessVoiceDACRequestReturn
                btst    #5,d6
                bne.w   Sound_ProcessVoiceDACRequestReturn
                cmpi.b  #2,(SoundVoiceDuckingState).w
                beq.w   Sound_ProcessVoiceDACRequestReturn
                move.b  #1,(SoundVoiceDuckingState).w
Sound_ProcessVoiceDACRequestReturn:                     ; was: locret_82BA0
                                        ; Sound_DispatchPendingRequest+16A   j
                rts
; ---------------------------------------------------------------------------
Sound_SelectVoiceDACPlaybackSlot:                       ; was: loc_82BA2
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForVoiceDACSlotStatusZ80Bus:                  ; was: loc_82BB0
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForVoiceDACSlotStatusZ80Bus
                move.b  (Z80DACStatus).l,d1
                move.b  (Z80VoiceSlotAFlags).l,d2
                move.b  (Z80VoiceSlotBFlags).l,d3
                move.b  (Z80VoiceSlotAActive).l,d4
                move.b  (Z80VoiceSlotBActive).l,d5
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                move.b  d1,d6
                move.b  5(a0),d0
                andi.b  #$C0,d0
                btst    #0,d1
                bne.w   Sound_EvaluateVoiceDACSlotSelection
                andi.b  #$C0,d1
                cmp.b   d1,d0
                bcs.w   Sound_RejectVoiceDACSlotRequest
Sound_EvaluateVoiceDACSlotSelection:                    ; was: loc_82BFE
                andi.b  #$C0,d2
                andi.b  #$C0,d3
                move.b  6(a0),d1
                andi.b  #$C0,d1
                beq.w   Sound_SelectAvailableVoiceDACSlot
                cmpi.b  #$C0,d1
                beq.w   Sound_SelectAvailableVoiceDACSlot
                tst.b   d1
                bpl.w   Sound_CompareSecondaryVoiceDACPriority
                cmp.b   d2,d0
                bcc.w   Sound_StartPrimaryVoiceDACSlot
                rts
; ---------------------------------------------------------------------------
Sound_CompareSecondaryVoiceDACPriority:                 ; was: loc_82C28
                cmp.b   d3,d0
                bcc.w   Sound_StartSecondaryVoiceDACSlot
Sound_RejectVoiceDACSlotRequest:                        ; was: locret_82C2E
                rts
; ---------------------------------------------------------------------------
Sound_SelectAvailableVoiceDACSlot:                      ; was: loc_82C30
                                        ; Sound_DispatchPendingRequest+1FC   j
                tst.b   d4
                beq.w   Sound_StartPrimaryVoiceDACSlot
                tst.b   d5
                beq.w   Sound_StartSecondaryVoiceDACSlot
                btst    #0,(SoundVoiceSlotToggle).w
                bne.w   Sound_SelectVoiceDACSlotByToggle
                cmp.b   d2,d0
                bcc.w   Sound_StartPrimaryVoiceDACSlot
                cmp.b   d3,d0
                bcc.w   Sound_StartSecondaryVoiceDACSlot
                rts
; ---------------------------------------------------------------------------
Sound_SelectVoiceDACSlotByToggle:                       ; was: loc_82C54
                cmp.b   d3,d0
                bcc.w   Sound_StartSecondaryVoiceDACSlot
                cmp.b   d2,d0
                bcc.w   Sound_StartPrimaryVoiceDACSlot
                rts
; ---------------------------------------------------------------------------
Sound_StartPrimaryVoiceDACSlot:                         ; was: loc_82C62
                                        ; Sound_DispatchPendingRequest+218   j
                bset    #0,(SoundVoiceSlotToggle).w
                bsr.w   Sound_ReadDACSampleHeader
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForPrimaryVoiceDACZ80Bus:                     ; was: loc_82C7A
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForPrimaryVoiceDACZ80Bus
                btst    #0,d6
                bne.w   Sound_WritePrimaryVoiceDACMailbox
                move.b  #$80,(Z80DACCommandByte4).l
                move.b  #$80,(Z80DACRequestState).l
Sound_WritePrimaryVoiceDACMailbox:                      ; was: loc_82C9C
                move.b  #$80,(Z80VoiceSlotAActive).l
                move.b  0.w(a0),(Z80VoiceSlotADesc0).l
                move.b  1(a0),(Z80VoiceSlotADesc1).l
                move.b  d2,(Z80VoiceSlotAHeader0).l
                move.b  d3,(Z80VoiceSlotAHeader1).l
                move.b  d4,(Z80VoiceSlotAHeader2).l
                move.b  d5,(Z80VoiceSlotAHeader3).l
                move.b  5(a0),(Z80DACCommandByte5).l
                move.b  5(a0),(Z80VoiceSlotAFlags).l
                move.b  #$C0,(Z80DACCommandByte6).l
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                btst    #5,5(a0)
                beq.w   Sound_StartPrimaryVoiceDACSlotReturn
                btst    #5,d6
                bne.w   Sound_StartPrimaryVoiceDACSlotReturn
                cmpi.b  #2,(SoundVoiceDuckingState).w
                beq.w   Sound_StartPrimaryVoiceDACSlotReturn
                move.b  #1,(SoundVoiceDuckingState).w
Sound_StartPrimaryVoiceDACSlotReturn:                   ; was: locret_82D10
                                        ; Sound_DispatchPendingRequest+2E2   j
                rts
; ---------------------------------------------------------------------------
Sound_StartSecondaryVoiceDACSlot:                       ; was: loc_82D12
                                        ; Sound_DispatchPendingRequest+21E   j
                bclr    #0,(SoundVoiceSlotToggle).w
                bsr.w   Sound_ReadDACSampleHeader
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForSecondaryVoiceDACZ80Bus:                   ; was: loc_82D2A
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForSecondaryVoiceDACZ80Bus
                btst    #0,d6
                bne.w   Sound_WriteSecondaryVoiceDACMailbox
                move.b  #$80,(Z80DACCommandByte4).l
                move.b  #$80,(Z80DACRequestState).l
; Write the selected sample header and descriptor fields to the secondary Z80 DAC mailbox
Sound_WriteSecondaryVoiceDACMailbox:                    ; was: loc_82D4C
                move.b  #$80,(Z80VoiceSlotBActive).l
                move.b  0.w(a0),(Z80VoiceSlotBDesc0).l
                move.b  1(a0),(Z80VoiceSlotBDesc1).l
                move.b  d2,(Z80VoiceSlotBHeader0).l
                move.b  d3,(Z80VoiceSlotBHeader1).l
                move.b  d4,(Z80VoiceSlotBHeader2).l
                move.b  d5,(Z80VoiceSlotBHeader3).l
                move.b  5(a0),(Z80DACCommandByte5).l
                move.b  5(a0),(Z80VoiceSlotBFlags).l
                move.b  #$C0,(Z80DACCommandByte6).l
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                btst    #5,5(a0)
                beq.w   Sound_StartSecondaryVoiceDACSlotReturn
                btst    #5,d6
                bne.w   Sound_StartSecondaryVoiceDACSlotReturn
                cmpi.b  #2,(SoundVoiceDuckingState).w
                beq.w   Sound_StartSecondaryVoiceDACSlotReturn
                move.b  #1,(SoundVoiceDuckingState).w
Sound_StartSecondaryVoiceDACSlotReturn:                 ; was: locret_82DC0
                                        ; Sound_DispatchPendingRequest+392   j
                rts
; End of function Sound_DispatchPendingRequest
; Resolve the packed sample pointer and read the four-byte DPCM sample header
Sound_ReadDACSampleHeader:                              ; was: sub_82DC2
                                        ; Sound_DispatchPendingRequest+2FE   p
                moveq   #0,d0
                move.w  0.w(a0),d0
                lsl.l   #8,d0
                movea.l d0,a2
                move.b  3(a0),d0
                lsl.w   #8,d0
                move.b  2(a0),d0
                andi.w  #$7FFF,d0
                move.b  (a2,d0.w),d2
                move.b  1(a2,d0.w),d3
                move.b  2(a2,d0.w),d4
                move.b  3(a2,d0.w),d5
                rts
; End of function Sound_ReadDACSampleHeader
; ---------------------------------------------------------------------------
Sound_VoiceDACDescriptors:  dc.w    (Sound_PCMBank3 >> $8)  ; was: word_82DEC
                                        ; 980 - Sound_PCMBank1
                                        ; A00 - Sound_PCMBank2
                                        ; A80 - Sound_PCMBank3
                                        ; B00 - Sound_PCMBank4
                                        ; B80 - Sound_PCMBank5
                                        ; C00 - Sound_PCMBank6
                                        ; C80 - Sound_PCMBank7
                                        ; D00 - Sound_PCMBank8
                                        ; D80 - Sound_PCMBank9
                dc.w    $880, $380, $C000
                dc.w    (Sound_PCMBank3 >> $8)
                dc.w    $80, $1380, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $880, $180, $C000
                dc.w    (Sound_PCMBank3 >> $8)
                dc.w    $80, $1B80, $C000
                dc.w    (Sound_PCMBank3 >> $8)
                dc.w    $480, $4580, $C000
                dc.w    (Sound_PCMBank5 >> $8)
                dc.w    $880, $1381, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $480, $1381, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $880, $1381, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $1480, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $1880, $2081, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $1080, $13A1, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $480, $13A1, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $1880, $1381, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $2480, $4080, $C000
                dc.w    (Sound_PCMBank3 >> $8)
                dc.w    $1080, $13C1, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $80, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $2080, $1381, $C000
                dc.w    (Sound_PCMBank7 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank5 >> $8)
                dc.w    $480, $280, $C000
                dc.w    (Sound_PCMBank6 >> $8)
                dc.w    $80, $280, $C000
                dc.w    (Sound_PCMBank5 >> $8)
                dc.w    $1080, $280, $C000
                dc.w    (Sound_PCMBank6 >> $8)
                dc.w    $880, $280, $C000
                dc.w    (Sound_PCMBank7 >> $8)
                dc.w    $480, $280, $C000
                dc.w    (Sound_PCMBank7 >> $8)
                dc.w    $880, $280, $C000
                dc.w    (Sound_PCMBank6 >> $8)
                dc.w    $480, $280, $C000
                dc.w    (Sound_PCMBank5 >> $8)
                dc.w    $80, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $480, $380, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $2480, $1A80, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $2480, $2780, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $2880, $1381, $C000
                dc.w    (Sound_PCMBank5 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $80, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $880, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $2080, $1880, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $2880, $1381, $C000
                dc.w    (Sound_PCMBank6 >> $8)
                dc.w    $C80, $1381, $C000
                dc.w    (Sound_PCMBank7 >> $8)
                dc.w    $1080, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $1080, $1381, $C000
                dc.w    (Sound_PCMBank8 >> $8)
                dc.w    $1480, $1381, $C000
                dc.w    (Sound_PCMBank9 >> $8)
                dc.w    $80, $1A80, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $1C80, $180, $C000
                dc.w    (Sound_PCMBank7 >> $8)
                dc.w    $80, $280, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $1C80, $1381, $C000
                dc.w    (Sound_PCMBank4 >> $8)
                dc.w    $2080, $1381, $C000
                dc.w    (Sound_PCMBank2 >> $8)
                dc.w    $1C80, $180, $C000

; End of pending-request dispatch and voice DAC data
