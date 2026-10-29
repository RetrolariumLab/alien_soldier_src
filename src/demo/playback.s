Demo_PlaybackSystem:                                    ; was: sub_23CBA
                tst.w   (DemoPlaybackActive).w
                beq.w   Demo_PlaybackSystem_Return
                move.w  #0,(DemoRecordingMode).w
                tst.w   (DemoPlaybackState).w
                bne.w   Demo_PlaybackSystem_Update
                move.l  #$8522BD7A,(RandomNumberState).w
                clr.w   (VBlankFrameCounter).w
                clr.w   (FrameCounter).w
                move.w  (DifficultyMode).w,(SavedDifficultyMode).w
                move.w  (SoundDisableFlags).w,(SavedSoundDisableFlags).w
                move.b  (ControlLayoutFlags).w,(SavedControlLayoutFlags).w
                move.w  #2,(DifficultyMode).w
                move.w  #0,(SoundDisableFlags).w
                move.b  #0,(ControlLayoutFlags).w
                clr.w   (DemoCurrentInputWord).w
                move.w  (DemoRotationIndex).w,d0
                andi.w  #6,d0
                lea     Demo_StageIndexTable(pc),a0
                nop
                move.w  (a0,d0.w),(DemoStageTableIndex).w
                lsl.w   #1,d0
                jsr     Demo_GetInputPointer(pc)        ; (pc)
                nop
                move.w  (a0)+,(DemoInputRunFrames).w
                move.l  a0,(DemoInputStreamPtr).w
                move.w  #$1000,(DemoFramesRemaining).w
                addq.w  #4,(DemoPlaybackState).w
                tst.w   (DemoRecordingMode).w
                beq.w   Demo_PlaybackSystem_Return
                clr.w   (DemoRecordingOffset).w
                clr.w   (DemoInputRunFrames).w
Demo_PlaybackSystem_Return:                             ; was: locret_23D46
                                        ; Demo_PlaybackSystem+80   j
                rts
; ---------------------------------------------------------------------------
Demo_PlaybackSystem_Update:                             ; was: loc_23D48
                tst.w   (DataLoaderControl).w
                bmi.w   Demo_PlaybackSystem_CheckFramesRemaining
                btst    #7,(ControllerPressedState).w
                bne.w   Demo_PlaybackSystem_Exit
Demo_PlaybackSystem_CheckFramesRemaining:               ; was: loc_23D5A
                tst.w   (DemoFramesRemaining).w
                beq.w   Demo_PlaybackSystem_Exit
                cmpi.w  #$80,(DemoFramesRemaining).w
                bne.s   Demo_PlaybackSystem_ProcessInput
                move.b  #1,(SoundFadeOutDelay).w
Demo_PlaybackSystem_ProcessInput:                       ; was: loc_23D70
                bsr.w   Demo_HandlePlaybackInput
                tst.w   (DemoRecordingMode).w
                bne.s   Demo_PlaybackSystem_DecrementTimer
                move.b  (DemoPlaybackInputWord).w,(ControllerHeldState).w
                move.b  (DemoPlaybackInputWord+1).w,(ControllerPressedState).w
Demo_PlaybackSystem_DecrementTimer:                     ; was: loc_23D86
                subq.w  #1,(DemoFramesRemaining).w
                rts
; ---------------------------------------------------------------------------
Demo_PlaybackSystem_Exit:                               ; was: loc_23D8C
                                        ; Demo_PlaybackSystem+A4   j
                clr.b   (SoundPauseState).w
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                clr.w   (DemoPlaybackActive).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.w  (SavedDifficultyMode).w,(DifficultyMode).w
                move.w  (SavedSoundDisableFlags).w,(SoundDisableFlags).w
                move.b  (SavedControlLayoutFlags).w,(ControlLayoutFlags).w
                addq.w  #2,(DemoRotationIndex).w
                andi.w  #6,(DemoRotationIndex).w
                move.b  #4,(SoundRequestQueue).w
                lea     (PaletteActiveBuffer).w,a0
                moveq   #0,d0
                move.w  #$3F,d1                         ; '?'
Demo_PlaybackSystem_ClearPaletteBufferLoop:             ; was: loc_23DD2
                move.l  d0,(a0)+
                dbf     d1,Demo_PlaybackSystem_ClearPaletteBufferLoop
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.w  (VDPReg1Shadow).w,(VDP_CTRL).l
                move.b  #0,(VDPReg18Shadow+1).w
                move.w  (VDPReg18Shadow).w,(VDP_CTRL).l
                move.b  #$10,(VDPReg7Shadow+1).w
                move.w  (VDPReg7Shadow).w,(VDP_CTRL).l
                andi.b  #$EF,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                rts
; End of function Demo_PlaybackSystem
; Handles demo playback mode with input recording and frame timing
Demo_HandlePlaybackInput:                               ; was: sub_23E16
                tst.w   (DemoRecordingMode).w
                bne.w   Demo_HandlePlaybackInput_Record
                move.w  (DemoCurrentInputWord).w,(DemoPlaybackInputWord).w
                subq.w  #1,(DemoInputRunFrames).w
                bne.w   Demo_PlaybackSystem_Return
                movea.l (DemoInputStreamPtr).w,a0
                move.w  (a0)+,(DemoCurrentInputWord).w
                move.w  (a0)+,(DemoInputRunFrames).w
                move.l  a0,(DemoInputStreamPtr).w
                rts
; ---------------------------------------------------------------------------
Demo_HandlePlaybackInput_Record:                        ; was: loc_23E3E
                move.b  (ControllerHeldState).w,d0
                lsl.w   #8,d0
                move.b  (ControllerPressedState).w,d0
                cmp.w   (DemoCurrentInputWord).w,d0
                bne.s   Demo_HandlePlaybackInput_AppendRecord
                addq.w  #1,(DemoInputRunFrames).w
                rts
; ---------------------------------------------------------------------------
Demo_HandlePlaybackInput_AppendRecord:                  ; was: loc_23E54
                lea     ($FFFC0000).l,a1
                movea.w (DemoRecordingOffset).w,a0
                move.w  (DemoInputRunFrames).w,(a1,a0.w)
                move.w  d0,2(a1,a0.w)
                move.b  (ControllerHeldState).w,(DemoCurrentInputWord).w
                move.b  (ControllerPressedState).w,(DemoCurrentInputWord+1).w
                move.w  #1,(DemoInputRunFrames).w
                addi.w  #4,(DemoRecordingOffset).w
                rts
; End of function Demo_HandlePlaybackInput
; Returns appropriate input data pointer for demo playback or recording
Demo_GetInputPointer:                                   ; was: sub_23E82
                tst.w   (DemoRecordingMode).w
                bne.s   Demo_GetInputPointer_UseRecordingBuffer
                movea.l Demo_InputStreamPointers(pc,d0.w),a0
                rts
; ---------------------------------------------------------------------------
Demo_GetInputPointer_UseRecordingBuffer:                ; was: loc_23E8E
                lea     ($FFFC0000).l,a0
                rts
; End of function Demo_GetInputPointer
; ---------------------------------------------------------------------------
Demo_StageIndexTable:       dc.w    2, $E, $12, $1E     ; was: word_23E96
Demo_InputStreamPointers:   dc.l    Demo_InputStream0   ; was: off_23E9E
                dc.l    Demo_InputStream1
                dc.l    Demo_InputStream2
                dc.l    Demo_InputStream3
Demo_InputStream0:  binclude "data/other/word_23EAE.bin"  ; was: word_23EAE
Demo_InputStream0_End:                                  ; was: word_23EAE_End
Demo_InputStream1:  binclude "data/other/word_24A50.bin"  ; was: word_24A50
Demo_InputStream1_End:                                  ; was: word_24A50_End
Demo_InputStream2:  binclude "data/other/word_25142.bin"  ; was: word_25142
Demo_InputStream2_End:                                  ; was: word_25142_End
Demo_InputStream3:  binclude "data/other/word_259C8.bin"  ; was: word_259C8
Demo_InputStream3_End:                                  ; was: word_259C8_End

; Decompresses cutscene graphics data
