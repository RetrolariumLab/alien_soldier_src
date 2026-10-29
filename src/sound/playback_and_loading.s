; Load a BGM sequence from IDs $81-$9F
Sound_LoadBGMRequest:                                   ; was: sub_82F6C
                cmpi.b  #$A0,d7
                bcs.w   Sound_InitializeBGM
                rts
; ---------------------------------------------------------------------------
Sound_InitializeBGM:
                jsr     Sound_StopSFXAndRestoreBGMChannels(pc)  ; (pc)
                jsr     Sound_StopSpecialSFXAndRestoreBGMChannels(pc)  ; (pc)
                jsr     Sound_ResetPlaybackState(pc)    ; (pc)
                lea     Sound_BGMPointerTable(pc),a4
                subi.b  #$81,d7
                lsl.w   #2,d7
                movea.l (a4,d7.w),a4
                moveq   #0,d0
                move.w  (a4),d0
                add.l   a4,d0
                move.l  d0,(SoundBGMDataPtr).w
                move.b  5(a4),(SoundTempoReload).w
                move.b  5(a4),(SoundTempoCounter).w
                moveq   #0,d1
                movea.l a4,a3
                addq.w  #6,a4
                moveq   #0,d7
                move.b  2(a3),d7
                beq.s   Sound_InitializeBGMPSGChannels
                subq.b  #1,d7
                move.b  #$C0,d1
                move.b  #$80,d3
                move.b  4(a3),d4
                moveq   #$30,d6                         ; '0'
                move.b  #1,d5
                lea     (SoundPCMChannelRecord).w,a1
                lea     Sound_BGMFMChannelTypes(pc),a2
Sound_InitializeNextBGMFMChannel:                       ; was: loc_82FD0
                move.b  d3,(a1)
                move.b  (a2)+,1(a1)
                move.b  d4,2(a1)
                move.b  d6,$D(a1)
                move.b  d1,$27(a1)
                move.b  d5,$E(a1)
                moveq   #0,d0
                move.w  (a4)+,d0
                add.l   a3,d0
                move.l  d0,4(a1)
                move.w  (a4)+,8(a1)
                adda.w  d6,a1
                dbf     d7,Sound_InitializeNextBGMFMChannel
Sound_InitializeBGMPSGChannels:                         ; was: loc_82FFA
                moveq   #0,d7
                move.b  3(a3),d7
                beq.s   Sound_MarkBGMChannelsOverriddenBySFX
                subq.b  #1,d7
                lea     (SoundBGMPSGChannels).w,a1
                lea     Sound_BGMPSGChannelTypes(pc),a2
Sound_InitializeNextBGMPSGChannel:                      ; was: loc_8300C
                move.b  d3,(a1)
                move.b  (a2)+,1(a1)
                move.b  d4,2(a1)
                move.b  d6,$D(a1)
                move.b  d5,$E(a1)
                moveq   #0,d0
                move.w  (a4)+,d0
                add.l   a3,d0
                move.l  d0,4(a1)
                move.w  (a4)+,8(a1)
                move.b  (a4)+,$A(a1)
                move.b  (a4)+,$B(a1)
                adda.w  d6,a1
                dbf     d7,Sound_InitializeNextBGMPSGChannel
Sound_MarkBGMChannelsOverriddenBySFX:                   ; was: loc_8303A
                lea     (SoundSFXFMChannels).w,a1
                moveq   #5,d7
Sound_CheckNextActiveSFXChannel:                        ; was: loc_83040
                tst.b   (a1)
                bpl.w   Sound_ContinueActiveSFXChannelScan
                moveq   #0,d0
                move.b  1(a1),d0
                bmi.s   Sound_MapPSGSFXChannelIndex
                subq.b  #2,d0
                lsl.b   #2,d0
                bra.s   Sound_MarkBGMChannelOverridden
; ---------------------------------------------------------------------------
Sound_MapPSGSFXChannelIndex:                            ; was: loc_83054
                lsr.b   #3,d0
Sound_MarkBGMChannelOverridden:                         ; was: loc_83056
                lea     Sound_BGMChannelRecordPointers(pc),a0
                movea.l (a0,d0.w),a0
                bset    #2,(a0)
Sound_ContinueActiveSFXChannelScan:                     ; was: loc_83062
                adda.w  d6,a1
                dbf     d7,Sound_CheckNextActiveSFXChannel
                tst.w   (SoundSpecialSFXFM).w
                bpl.s   Sound_MarkSpecialFMOverrideForBGM
                bset    #2,(SoundBGMFMChannel3).w
Sound_MarkSpecialFMOverrideForBGM:                      ; was: loc_83074
                tst.w   (SoundSpecialSFXPSG).w
                bpl.s   Sound_RefreshBGMFMChannels
                bset    #2,(SoundBGMPSGChannel2).w
Sound_RefreshBGMFMChannels:                             ; was: loc_83080
                lea     (SoundBGMFMChannels).w,a5
                moveq   #5,d4
Sound_RefreshNextBGMFMChannel:                          ; was: loc_83086
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
                adda.w  d6,a5
                dbf     d4,Sound_RefreshNextBGMFMChannel
                moveq   #2,d4
Sound_RefreshBGMPSGChannels:                            ; was: loc_83092
                jsr     Sound_MutePSGIfNotOverridden(pc)  ; (pc)
                adda.w  d6,a5
                dbf     d4,Sound_RefreshBGMPSGChannels
                btst    #2,(SoundBGMPSGChannel2).w
                bne.s   Sound_FinishBGMInitialization
                move.b  #$FF,(VDP_PSG).l
; Discard the caller's BGM-load return address and finish initialization
Sound_FinishBGMInitialization:                          ; was: loc_830AC
                addq.w  #4,sp
                rts
; End of function Sound_LoadBGMRequest
; ---------------------------------------------------------------------------
Sound_BGMFMChannelTypes:    dc.b    6, 0, 1, 2, 4, 5, 6, 0  ; was: byte_830B0
Sound_BGMPSGChannelTypes:   dc.b    $80, $A0, $C0, 0    ; was: byte_830B8

; Loads regular SFX IDs $40-$7F and $A0-$F8 into the sound channels
Sound_LoadSFX:                                          ; was: sub_830BC
                cmpi.b  #$80,d7
                bcs.w   Sound_SelectLowRangeSFXPointerTable
                rts
; ---------------------------------------------------------------------------
Sound_SelectLowRangeSFXPointerTable:                    ; was: loc_830C6
                lea     Sound_OrdinarySFXPointerTableBase(pc),a0
                addi.w  #$1D,d7
                bra.w   Sound_ResolveSFXHeader
; ---------------------------------------------------------------------------
Sound_ValidateHighRangeSFXRequest:                      ; was: loc_830D2
                cmpi.b  #$F9,d7
                bcs.w   Sound_SelectHighRangeSFXPointerTable
                rts
; ---------------------------------------------------------------------------
Sound_SelectHighRangeSFXPointerTable:                   ; was: loc_830DC
                lea     Sound_OrdinarySFXPointerTableBase(pc),a0
                subi.b  #$A0,d7
Sound_ResolveSFXHeader:                                 ; was: loc_830E4
                lsl.w   #2,d7
                movea.l (a0,d7.w),a3
                movea.l a3,a1
                moveq   #0,d1
                move.w  (a1)+,d1
                add.l   a3,d1
                move.b  (a1)+,d5
                moveq   #0,d7
                move.b  (a1)+,d7
                subq.w  #1,d7
                moveq   #$30,d6                         ; '0'
Sound_InitializeNextSFXChannel:                         ; was: loc_830FC
                moveq   #0,d3
                move.b  1(a1),d3
                move.b  d3,d4
                bmi.s   Sound_MapSFXPSGChannel
                subq.w  #2,d3
                lsl.w   #2,d3
                lea     Sound_BGMChannelRecordPointers(pc),a5
                movea.l (a5,d3.w),a5
                bset    #2,(a5)
                bra.s   Sound_ClearAndInitializeSFXChannel
; ---------------------------------------------------------------------------
Sound_MapSFXPSGChannel:                                 ; was: loc_83118
                lsr.w   #3,d3
                movea.l Sound_BGMChannelRecordPointers(pc,d3.w),a5
                bset    #2,(a5)
                cmpi.b  #$C0,d4
                bne.s   Sound_ClearAndInitializeSFXChannel
                move.b  d4,d0
                ori.b   #$1F,d0
                move.b  d0,(VDP_PSG).l
                bchg    #5,d0
                move.b  d0,(VDP_PSG).l
Sound_ClearAndInitializeSFXChannel:                     ; was: loc_8313E
                                        ; Sound_LoadSFX+6A   j
                movea.l Sound_SFXChannelRecordPointers(pc,d3.w),a5
                movea.l a5,a2
                moveq   #$B,d0
Sound_ClearSFXChannelRecordLoop:                        ; was: loc_83146
                clr.l   (a2)+
                dbf     d0,Sound_ClearSFXChannelRecordLoop
                move.l  d1,$20(a5)
                move.w  (a1)+,(a5)
                move.b  d5,2(a5)
                moveq   #0,d0
                move.w  (a1)+,d0
                add.l   a3,d0
                move.l  d0,4(a5)
                move.w  (a1)+,8(a5)
                move.b  #1,$E(a5)
                move.b  d6,$D(a5)
                tst.b   d4
                bmi.s   Sound_ContinueSFXChannelInitialization
                move.b  #$C0,$27(a5)
Sound_ContinueSFXChannelInitialization:                 ; was: loc_83178
                dbf     d7,Sound_InitializeNextSFXChannel
                tst.b   (SoundSFXFMChannel1).w
                bpl.s   Sound_MarkSpecialFMChannelOverridden
                bset    #2,(SoundSpecialSFXFM).w
Sound_MarkSpecialFMChannelOverridden:                   ; was: loc_83188
                tst.b   (SoundSFXPSGChannel2).w
                bpl.s   Sound_LoadSFXReturn
                bset    #2,(SoundSpecialSFXPSG).w
Sound_LoadSFXReturn:                                    ; was: locret_83194
                rts
; End of function Sound_LoadSFX
; ---------------------------------------------------------------------------
Sound_BGMChannelRecordPointers: dc.l    $FFFFF8D0, 0    ; was: dword_83196
                                        ; Sound_LoadSFX+4E   o
                dc.l    $FFFFF900, $FFFFF930
                dc.l    $FFFFF990, $FFFFF9C0
                dc.l    $FFFFF9F0, $FFFFF9F0
Sound_SFXChannelRecordPointers: dc.l    $FFFFFA20, 0    ; was: dword_831B6
                dc.l    $FFFFFA50, $FFFFFA80
                dc.l    $FFFFFAB0, $FFFFFAE0
                dc.l    $FFFFFB10, $FFFFFB10

; Loads special SFX IDs $F9-$FC into the dedicated override channels
Sound_LoadSpecialSFX:                                   ; was: sub_831D6
                cmpi.b  #$FD,d7
                bcs.w   Sound_ResolveSpecialSFXHeader
                rts
; ---------------------------------------------------------------------------
Sound_ResolveSpecialSFXHeader:                          ; was: loc_831E0
                lea     Sound_SpecialSFXPointerTable(pc),a0
                subi.b  #$F9,d7
                lsl.w   #2,d7
                movea.l (a0,d7.w),a3
                movea.l a3,a1
                moveq   #0,d0
                move.w  (a1)+,d0
                add.l   a3,d0
                move.l  d0,(SoundSpecialSFXDataPtr).w
                move.b  (a1)+,d5
                moveq   #0,d7
                move.b  (a1)+,d7
                subq.w  #1,d7
                moveq   #$30,d6                         ; '0'
Sound_InitializeNextSpecialSFXChannel:                  ; was: loc_83204
                move.b  1(a1),d4
                bmi.s   Sound_SelectSpecialSFXPSGChannel
                bset    #2,(SoundBGMFMChannel3).w
                lea     (SoundSpecialSFXFM).w,a5
                bra.s   Sound_ClearAndInitializeSpecialSFXChannel
; ---------------------------------------------------------------------------
Sound_SelectSpecialSFXPSGChannel:                       ; was: loc_83216
                bset    #2,(SoundBGMPSGChannel2).w
                lea     (SoundSpecialSFXPSG).w,a5
Sound_ClearAndInitializeSpecialSFXChannel:              ; was: loc_83220
                movea.l a5,a2
                moveq   #$B,d0
Sound_ClearSpecialSFXChannelRecordLoop:                 ; was: loc_83224
                clr.l   (a2)+
                dbf     d0,Sound_ClearSpecialSFXChannelRecordLoop
                move.w  (a1)+,(a5)
                move.b  d5,2(a5)
                moveq   #0,d0
                move.w  (a1)+,d0
                add.l   a3,d0
                move.l  d0,4(a5)
                move.w  (a1)+,8(a5)
                move.b  #1,$E(a5)
                move.b  d6,$D(a5)
                tst.b   d4
                bmi.s   Sound_ContinueSpecialSFXChannelInitialization
                move.b  #$C0,$27(a5)
Sound_ContinueSpecialSFXChannelInitialization:          ; was: loc_83252
                dbf     d7,Sound_InitializeNextSpecialSFXChannel
                tst.b   (SoundSFXFMChannel1).w
                bpl.s   Sound_MarkSpecialPSGChannelOverridden
                bset    #2,(SoundSpecialSFXFM).w
Sound_MarkSpecialPSGChannelOverridden:                  ; was: loc_83262
                tst.b   (SoundSFXPSGChannel2).w
                bpl.s   Sound_LoadSpecialSFXReturn
                bset    #2,(SoundSpecialSFXPSG).w
                ori.b   #$1F,d4
                move.b  d4,(VDP_PSG).l
                bchg    #5,d4
                move.b  d4,(VDP_PSG).l
Sound_LoadSpecialSFXReturn:                             ; was: locret_83282
                rts
; End of function Sound_LoadSpecialSFX
; ---------------------------------------------------------------------------
Sound_UnreferencedSFXChannelPointers:   binclude "data/other/unused_10.bin"  ; was: unused_10

; Stop ordinary SFX channels and restore any BGM channels they displaced
Sound_StopSFXAndRestoreBGMChannels:                     ; was: sub_8329C
                                        ; Sound_LoadBGMRequest:Sound_InitializeBGM   p
                clr.b   (SoundCurrentPriority).w
                moveq   #$27,d0                         ; '''
                moveq   #0,d1
                jsr     Sound_WriteYM2612Port0Thunk(pc)  ; (pc)
                lea     (SoundSFXFMChannels).w,a5
                moveq   #5,d6
Sound_StopNextSFXChannel:                               ; was: loc_832AE
                tst.b   (a5)
                bpl.w   Sound_ContinueSFXChannelStopLoop
                bclr    #7,(a5)
                moveq   #0,d3
                move.b  1(a5),d3
                bmi.s   Sound_RestoreBGMPSGChannel
                jsr     Sound_SendFMKeyOffIfAllowed(pc)  ; (pc)
                cmpi.b  #4,d3
                bne.s   Sound_SelectOverriddenBGMFMChannel
                tst.b   (SoundSpecialSFXFM).w
                bpl.s   Sound_SelectOverriddenBGMFMChannel
                lea     (SoundSpecialSFXFM).w,a5
                movea.l (SoundSpecialSFXDataPtr).w,a1
                bra.s   Sound_RestoreBGMFMChannel
; ---------------------------------------------------------------------------
Sound_SelectOverriddenBGMFMChannel:                     ; was: loc_832DA
                                        ; Sound_StopSFXAndRestoreBGMChannels+32   j
                subq.b  #2,d3
                lsl.b   #2,d3
                lea     Sound_BGMChannelRecordPointers(pc),a0
                movea.l a5,a3
                movea.l (a0,d3.w),a5
                movea.l (SoundBGMDataPtr).w,a1
Sound_RestoreBGMFMChannel:                              ; was: loc_832EC
                bclr    #2,(a5)
                bset    #1,(a5)
                move.b  $B(a5),d0
                jsr     Sound_ProgramFMInstrument(pc)   ; (pc)
                movea.l a3,a5
                bra.s   Sound_ContinueSFXChannelStopLoop
; ---------------------------------------------------------------------------
Sound_RestoreBGMPSGChannel:                             ; was: loc_83300
                jsr     Sound_MutePSGIfNotOverridden(pc)  ; (pc)
                lea     (SoundSpecialSFXPSG).w,a0
                cmpi.b  #$E0,d3
                beq.s   Sound_MarkBGMPSGChannelRestored
                cmpi.b  #$C0,d3
                beq.s   Sound_MarkBGMPSGChannelRestored
                lsr.b   #3,d3
                lea     Sound_BGMChannelRecordPointers(pc),a0
                movea.l (a0,d3.w),a0
Sound_MarkBGMPSGChannelRestored:                        ; was: loc_8331E
                                        ; Sound_StopSFXAndRestoreBGMChannels+76   j
                bclr    #2,(a0)
                bset    #1,(a0)
                cmpi.b  #$E0,1(a0)
                bne.s   Sound_ContinueSFXChannelStopLoop
                move.b  $25(a0),(VDP_PSG).l
Sound_ContinueSFXChannelStopLoop:                       ; was: loc_83336
                                        ; Sound_StopSFXAndRestoreBGMChannels+62   j
                adda.w  #$30,a5                         ; '0'
                dbf     d6,Sound_StopNextSFXChannel
                rts
; End of function Sound_StopSFXAndRestoreBGMChannels
; Stop the dedicated override channels and restore their displaced BGM channels
Sound_StopSpecialSFXAndRestoreBGMChannels:              ; was: sub_83340
                                        ; Sound_LoadBGMRequest+E   p
                lea     (SoundSpecialSFXFM).w,a5
                tst.b   (a5)
                bpl.s   Sound_StopSpecialSFXPSGChannel
                bclr    #7,(a5)
                btst    #2,(a5)
                bne.s   Sound_StopSpecialSFXPSGChannel
                jsr     Sound_SendFMKeyOff(pc)          ; (pc)
                lea     (SoundBGMFMChannel3).w,a5
                bclr    #2,(a5)
                bset    #1,(a5)
                tst.b   (a5)
                bpl.s   Sound_StopSpecialSFXPSGChannel
                movea.l (SoundBGMDataPtr).w,a1
                move.b  $B(a5),d0
                jsr     Sound_ProgramFMInstrument(pc)   ; (pc)
Sound_StopSpecialSFXPSGChannel:                         ; was: loc_83372
                                        ; Sound_StopSpecialSFXAndRestoreBGMChannels+10   j
                lea     (SoundSpecialSFXPSG).w,a5
                tst.b   (a5)
                bpl.s   Sound_StopSpecialSFXAndRestoreBGMReturn
                bclr    #7,(a5)
                btst    #2,(a5)
                bne.s   Sound_StopSpecialSFXAndRestoreBGMReturn
                jsr     Sound_MutePSGChannel(pc)        ; (pc)
                lea     (SoundBGMPSGChannel2).w,a5
                bclr    #2,(a5)
                bset    #1,(a5)
                tst.b   (a5)
                bpl.s   Sound_StopSpecialSFXAndRestoreBGMReturn
                cmpi.b  #$E0,1(a5)
                bne.s   Sound_StopSpecialSFXAndRestoreBGMReturn
                move.b  $25(a5),(VDP_PSG).l
Sound_StopSpecialSFXAndRestoreBGMReturn:                ; was: locret_833A8
                                        ; Sound_StopSpecialSFXAndRestoreBGMChannels+42   j
                rts
; End of function Sound_StopSpecialSFXAndRestoreBGMChannels
; Start the 40-step music fade-out at one volume step every four frames
Sound_StartMusicFadeOut:                                ; was: sub_833AA
                move.b  #3,(SoundFadeTickCounter).w
                move.b  #$28,(SoundFadeStepsRemaining).w  ; '('
                clr.b   (SoundPCMChannelRecord).w
                rts
; End of function Sound_StartMusicFadeOut
; Advance the active music fade-out timer and channel attenuation
Sound_UpdateMusicFadeOut:                               ; was: sub_833BC
                moveq   #0,d0
                move.b  (SoundFadeStepsRemaining).w,d0
                beq.s   Sound_UpdateMusicFadeOutReturn
                move.b  (SoundFadeTickCounter).w,d0
                beq.s   Sound_AdvanceMusicFadeOutStep
                subq.b  #1,(SoundFadeTickCounter).w
Sound_UpdateMusicFadeOutReturn:                         ; was: locret_833CE
                rts
; ---------------------------------------------------------------------------
Sound_AdvanceMusicFadeOutStep:                          ; was: loc_833D0
                subq.b  #1,(SoundFadeStepsRemaining).w
                beq.w   Sound_StopAllPlayback
                move.b  #3,(SoundFadeTickCounter).w
                lea     (SoundBGMFMChannels).w,a5
                moveq   #5,d7
Sound_FadeNextBGMFMChannel:                             ; was: loc_833E4
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMFMFadeLoop
                addq.b  #1,9(a5)
                bpl.s   Sound_ApplyBGMFMFadeVolume
                bclr    #7,(a5)
                bra.s   Sound_ContinueBGMFMFadeLoop
; ---------------------------------------------------------------------------
Sound_ApplyBGMFMFadeVolume:                             ; was: loc_833F4
                jsr     Sound_ApplyFMVolumeOffset(pc)   ; (pc)
Sound_ContinueBGMFMFadeLoop:                            ; was: loc_833F8
                                        ; Sound_UpdateMusicFadeOut+36   j
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_FadeNextBGMFMChannel
                moveq   #2,d7
Sound_FadeNextBGMPSGChannel:                            ; was: loc_83402
                tst.b   (a5)
                bpl.s   Sound_ContinueBGMPSGFadeLoop
                addq.b  #1,9(a5)
                cmpi.b  #$10,9(a5)
                bcs.s   Sound_ApplyBGMPSGFadeVolume
                bclr    #7,(a5)
                bra.s   Sound_ContinueBGMPSGFadeLoop
; ---------------------------------------------------------------------------
Sound_ApplyBGMPSGFadeVolume:                            ; was: loc_83418
                move.b  9(a5),d6
                jsr     Sound_ApplyPSGVolume(pc)        ; (pc)
; Continue the PSG fade-out channel loop
Sound_ContinueBGMPSGFadeLoop:                           ; was: loc_83420
                                        ; Sound_UpdateMusicFadeOut+5A   j
                adda.w  #$30,a5                         ; '0'
                dbf     d7,Sound_FadeNextBGMPSGChannel
                rts
; End of function Sound_UpdateMusicFadeOut
; Processes sound tempo tick and increments channel timers
Sound_ProcessTempoTick:                                 ; was: sub_8342A
                tst.b   (SoundTempoReload).w
                beq.s   Sound_ProcessTempoTickReturn
                subq.b  #1,(SoundTempoCounter).w
                bne.s   Sound_ProcessTempoTickReturn
                move.b  (SoundTempoReload).w,(SoundTempoCounter).w
                lea     (SoundPCMChannelRecord).w,a0
                moveq   #$30,d0                         ; '0'
                moveq   #9,d1
Sound_AdvanceNextChannelTempoTimer:                     ; was: loc_83444
                tst.b   (a0)
                bpl.s   Sound_ContinueChannelTempoLoop
                addq.b  #1,$E(a0)
Sound_ContinueChannelTempoLoop:                         ; was: loc_8344C
                adda.w  d0,a0
                dbf     d1,Sound_AdvanceNextChannelTempoTimer
Sound_ProcessTempoTickReturn:                           ; was: locret_83452
                                        ; Sound_ProcessTempoTick+A   j
                rts
; End of function Sound_ProcessTempoTick
; Maximize total level and release rate for all operators of the current FM channel
Sound_SilenceCurrentFMOperators:                        ; was: sub_83454
                moveq   #3,d4
                moveq   #$40,d3                         ; '@'
                moveq   #$7F,d1
Sound_SetNextFMOperatorTotalLevel:                      ; was: loc_8345A
                move.b  d3,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                addq.b  #4,d3
                dbf     d4,Sound_SetNextFMOperatorTotalLevel
                moveq   #3,d4
                move.b  #$80,d3
                moveq   #$F,d1
Sound_SetNextFMOperatorReleaseRate:                     ; was: loc_8346E
                move.b  d3,d0
                jsr     Sound_WriteCurrentFMChannelRegister(pc)  ; (pc)
                addq.b  #4,d3
                dbf     d4,Sound_SetNextFMOperatorReleaseRate
                rts
; End of function Sound_SilenceCurrentFMOperators
; Sends key-off to all FM channels
Sound_KeyOffAllFMChannels:                              ; was: sub_8347C
                moveq   #2,d2
                moveq   #$28,d0                         ; '('
Sound_KeyOffNextFMChannelPair:                          ; was: loc_83480
                move.b  d2,d1
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                addq.b  #4,d1
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                dbf     d2,Sound_KeyOffNextFMChannelPair
; End of function Sound_KeyOffAllFMChannels
; Set maximum attenuation on every operator of all six FM channels
Sound_SetAllFMOperatorLevelsMaximum:                    ; was: sub_83490
                moveq   #$7F,d1
                moveq   #2,d2
Sound_SetNextFMChannelOperatorLevels:                   ; was: loc_83494
                moveq   #$40,d0                         ; '@'
                add.w   d2,d0
                moveq   #3,d3
Sound_SetNextFMOperatorLevelMaximum:                    ; was: loc_8349A
                jsr     Sound_WriteYM2612Port0(pc)      ; (pc)
                jsr     Sound_WriteYM2612Port1(pc)      ; (pc)
                addq.w  #4,d0
                dbf     d3,Sound_SetNextFMOperatorLevelMaximum
                dbf     d2,Sound_SetNextFMChannelOperatorLevels
                rts
; End of function Sound_SetAllFMOperatorLevelsMaximum
; Clear playback state and silence every FM and PSG channel
Sound_StopAllPlayback:                                  ; was: sub_834AE
                                        ; Sound_DispatchPendingRequest+70   j
                moveq   #$27,d0                         ; '''
                moveq   #0,d1
                jsr     Sound_WriteYM2612Port0Thunk(pc)  ; (pc)
                lea     (SoundCurrentPriority).w,a0
                move.w  #$E3,d0
; Clear the playback-state region in longwords
Sound_ClearPlaybackRAMLoop:                             ; was: loc_834BE
                clr.l   (a0)+
                dbf     d0,Sound_ClearPlaybackRAMLoop
                move.b  #$FF,(SoundSelectedRequest).w
                jsr     Sound_KeyOffAllFMChannels(pc)   ; (pc)
                bra.w   Sound_MuteAllPSGChannels
; End of function Sound_StopAllPlayback
; Resets sound driver state and clears RAM
