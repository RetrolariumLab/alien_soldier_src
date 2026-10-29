Sound_ResetPlaybackState:                               ; was: sub_834D2
                moveq   #$27,d0                         ; '''
                moveq   #0,d1
                jsr     Sound_WriteYM2612Port0Thunk(pc)  ; (pc)
                move.b  (SoundCurrentPriority).w,d0
                move.w  d0,-(sp)
                lea     (SoundCurrentPriority).w,a0
                move.w  #$87,d0
; Resets sound RAM preserving settings
Sound_ClearPlaybackStateForBGM:                         ; was: loc_834E8
                clr.l   (a0)+
                dbf     d0,Sound_ClearPlaybackStateForBGM
                move.w  (sp)+,d0
                move.b  d0,(SoundCurrentPriority).w
                move.b  #$FF,(SoundSelectedRequest).w
                rts
; End of function Sound_ResetPlaybackState
; Loads Z80 sound driver code with bus request and reset sequence
Sound_LoadZ80Driver:                                    ; was: sub_834FC
                                        ; Sound_DispatchPendingRequest+E   j
                move    sr,-(sp)
                ori     #$700,sr
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusForDriverLoad:                       ; was: loc_8350A
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusForDriverLoad
                lea     Sound_Z80DriverProgram(pc),a0
                lea     (Z80_RAM).l,a1
                move.w  #$BFF,d0
Sound_CopyNextZ80DriverByte:                            ; was: loc_83522
                move.b  (a0)+,(a1)+
                dbf     d0,Sound_CopyNextZ80DriverByte
                move.w  #0,(IO_Z80RES).l
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  #$100,(IO_Z80RES).l
                move.w  #0,(IO_Z80BUS).l
                move    (sp)+,sr
                bra.w   Sound_StopAllPlayback
; End of function Sound_LoadZ80Driver
; Send key-on for all four FM operators unless the channel is held or overridden
Sound_SendFMKeyOn:                                      ; was: sub_83562
                btst    #1,(a5)
                bne.s   Sound_SendFMKeyOnReturn
                btst    #2,(a5)
                bne.s   Sound_SendFMKeyOnReturn
                moveq   #$28,d0                         ; '('
                move.b  1(a5),d1
                ori.b   #$F0,d1
                bra.w   Sound_WriteYM2612Port0Thunk
; ---------------------------------------------------------------------------
Sound_SendFMKeyOnReturn:                                ; was: locret_8357C
                                        ; Sound_SendFMKeyOn+A   j
                rts
; End of function Sound_SendFMKeyOn
; Send key-off unless the sequence hold or SFX-override flags suppress it
Sound_SendFMKeyOffIfAllowed:                            ; was: sub_8357E
                                        ; Sound_HandleNoteTimer+18   p
                btst    #4,(a5)
                bne.s   Sound_SendFMKeyOffSkippedReturn
                btst    #2,(a5)
                bne.s   Sound_SendFMKeyOffSkippedReturn
; End of function Sound_SendFMKeyOffIfAllowed
; Send key-off for all four FM operators on the current channel
Sound_SendFMKeyOff:                                     ; was: sub_8358A
                moveq   #$28,d0                         ; '('
                move.b  1(a5),d1
                bra.w   Sound_WriteYM2612Port0Thunk
; End of function Sound_SendFMKeyOff
Sound_SendFMKeyOffSkippedReturn:                        ; was: nullsub_137
                                        ; Sound_SendFMKeyOffIfAllowed+A   j
                rts
; End of function Sound_SendFMKeyOffSkippedReturn

; Suppress a current-channel register write while its BGM channel is overridden
Sound_WriteCurrentFMRegisterIfNotOverridden:            ; was: sub_83596
                                        ; Sound_WriteCurrentFMRegisterFromSequence+4   j
                btst    #2,(a5)
                beq.w   Sound_WriteCurrentFMChannelRegister
                rts
; End of function Sound_WriteCurrentFMRegisterIfNotOverridden
; Attributes: thunk
; Wrapper function redirecting to YM2612 register write
Sound_WriteYM2612Port0Thunk:                            ; was: sub_835A0
                                        ; Sound_StopAllPlayback+4   p
                bra.w   Sound_WriteYM2612Port0
; End of function Sound_WriteYM2612Port0Thunk
; Add the current FM channel number and select its YM2612 port
Sound_WriteCurrentFMChannelRegister:                    ; was: sub_835A4
                                        ; Sound_UpdateChannelFrequency+4A   p
                move.b  1(a5),d2
                bclr    #2,d2
                bne.s   Sound_WriteCurrentFMChannelRegisterPort1
                add.b   d2,d0
; End of function Sound_WriteCurrentFMChannelRegister
; Write an address/data pair to YM2612 port 0 with Z80 synchronization
Sound_WriteYM2612Port0:                                 ; was: sub_835B0
                                        ; Sound_UpdateFMOperators+28   p
                cmpi.b  #$50,d0                         ; 'P'
                bcc.w   Sound_PrepareYM2612Port0Write
                cmpi.b  #$40,d0                         ; '@'
                bcs.w   Sound_PrepareYM2612Port0Write
                andi.w  #$FF,d0
                lea     (SoundFMShadowIndexBase).w,a0
                move.b  d1,(a0,d0.w)
Sound_PrepareYM2612Port0Write:                          ; was: loc_835CC
                                        ; Sound_WriteYM2612Port0+C   j
                lea     (Z80_YM2612).l,a0
Sound_RequestZ80BusForYM2612Port0:                      ; was: loc_835D2
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusForYM2612Port0:                      ; was: loc_835DA
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusForYM2612Port0
                tst.b   (Z80DriverBusy).l
                beq.s   Sound_WaitForYM2612Port0AddressReady
                move.w  #0,(IO_Z80BUS).l
                bsr.w   Sound_DelayForZ80BusRetry
                bra.s   Sound_RequestZ80BusForYM2612Port0
; ---------------------------------------------------------------------------
Sound_WaitForYM2612Port0AddressReady:                   ; was: loc_835FA
                                        ; Sound_WriteYM2612Port0+4C   j
                tst.b   (a0)
                bmi.s   Sound_WaitForYM2612Port0AddressReady
                move.b  d0,0.w(a0)
                nop
Sound_WaitForYM2612Port0DataReady:                      ; was: loc_83604
                tst.b   (a0)
                bmi.s   Sound_WaitForYM2612Port0DataReady
                move.b  d1,1(a0)
                move.w  #0,(IO_Z80BUS).l
                rts
; End of function Sound_WriteYM2612Port0
; Add the channel number and continue through the YM2612 port 1 writer
Sound_WriteCurrentFMChannelRegisterPort1:               ; was: sub_83616
                add.b   d2,d0
; End of function Sound_WriteCurrentFMChannelRegisterPort1
; Write an address/data pair to YM2612 port 1 with Z80 synchronization
Sound_WriteYM2612Port1:                                 ; was: sub_83618
                                        ; Sound_SetAllFMOperatorLevelsMaximum+E   p
                cmpi.b  #$50,d0                         ; 'P'
                bcc.w   Sound_PrepareYM2612Port1Write
                cmpi.b  #$40,d0                         ; '@'
                bcs.w   Sound_PrepareYM2612Port1Write
                andi.w  #$FF,d0
                lea     (SoundFMShadowIndexBase).w,a0
                move.b  d1,SoundFMPort1IndexBase-SoundFMShadowIndexBase(a0,d0.w)
Sound_PrepareYM2612Port1Write:                          ; was: loc_83634
                                        ; Sound_WriteYM2612Port1+C   j
                lea     (Z80_YM2612).l,a0
Sound_RequestZ80BusForYM2612Port1:                      ; was: loc_8363A
                move.w  #$100,(IO_Z80BUS).l
Sound_WaitForZ80BusForYM2612Port1:                      ; was: loc_83642
                bset    #0,(IO_Z80BUS).l
                bne.s   Sound_WaitForZ80BusForYM2612Port1
                tst.b   (Z80DriverBusy).l
                beq.s   Sound_WaitForYM2612Port1AddressReady
                move.w  #0,(IO_Z80BUS).l
                bsr.w   Sound_DelayForZ80BusRetry
                bra.s   Sound_RequestZ80BusForYM2612Port1
; ---------------------------------------------------------------------------
Sound_WaitForYM2612Port1AddressReady:                   ; was: loc_83662
                                        ; Sound_WriteYM2612Port1+4C   j
                tst.b   (a0)
                bmi.s   Sound_WaitForYM2612Port1AddressReady
                move.b  d0,2(a0)
                nop
; Writes data byte to YM2612 with wait
Sound_WaitForYM2612Port1DataReady:                      ; was: loc_8366C
                tst.b   (a0)
                bmi.s   Sound_WaitForYM2612Port1DataReady
                move.b  d1,3(a0)
                move.w  #0,(IO_Z80BUS).l
                rts
; End of function Sound_WriteYM2612Port1
; Delay function with NOP instructions for timing
Sound_DelayForZ80BusRetry:                              ; was: sub_8367E
                                        ; Sound_WriteYM2612Port0+44   p
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                rts
; End of function Sound_DelayForZ80BusRetry
