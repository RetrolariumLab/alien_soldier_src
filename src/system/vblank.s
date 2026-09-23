VBLANK:                                                 ; DATA XREF: ROM:00000078   o
                move    #$2700,sr
Int_VBlank_AcquireZ80Bus:                               ; CODE XREF: VBLANK+C   j  ; was: loc_A7E
                bset    #0,(IO_Z80BUS).l
                bne.s   Int_VBlank_AcquireZ80Bus
                move.b  #1,(Z80VBlankActive).l
Int_VBlank_ReleaseZ80Bus:                               ; CODE XREF: VBLANK+1E   j  ; was: loc_A90
                bclr    #0,(IO_Z80BUS).l
                beq.s   Int_VBlank_ReleaseZ80Bus
                movem.l d0-d7/a0-a5,-(sp)
Int_VBlank_WaitForBlanking:                             ; CODE XREF: VBLANK+2E   j  ; was: loc_A9E
                move.w  (VDP_CTRL).l,d0
                andi.w  #8,d0
                beq.s   Int_VBlank_WaitForBlanking
                btst    #6,(ConsoleVersionFlags).w
                beq.w   Int_VBlank_RunEffects
                move.w  #$300,d0
Int_VBlank_PalDelayLoop:                                ; CODE XREF: VBLANK:Int_VBlank_PalDelayLoop   j  ; was: loc_AB8
                dbf     d0,Int_VBlank_PalDelayLoop
Int_VBlank_RunEffects:                                  ; CODE XREF: VBLANK+36   j  ; was: loc_ABC
                jsr     (VBlank_DispatchRasterEffect).l
                bsr.w   Gfx_ApplyHInterruptState
                tst.b   (SoundFadeOutDelay).w
                beq.s   Int_VBlank_UpdateFrameDivider
                subq.b  #1,(SoundFadeOutDelay).w
                bne.s   Int_VBlank_UpdateFrameDivider
                move.b  #1,(SoundRequestQueue+3).w
Int_VBlank_UpdateFrameDivider:                          ; CODE XREF: VBLANK+50   j  ; was: loc_AD8
                                        ; VBLANK+56   j
                subq.w  #1,(VBlankFrameDivider).w
                bpl.s   Int_VBlank_CheckExtendedHandler
                move.w  #4,d0
                sub.w   (FrameSkipLevel).w,d0
                move.w  d0,(VBlankFrameDivider).w
Int_VBlank_CheckExtendedHandler:                        ; CODE XREF: VBLANK+62   j  ; was: loc_AEA
                tst.b   (VBlankUpdateReady).w
                bne.s   Sys_VBlankHandler
Int_VBlank_AcquireZ80BusForExit:                        ; CODE XREF: VBLANK+7E   j  ; was: loc_AF0
                                        ; Sys_VBlankHandler+12   j
                bset    #0,(IO_Z80BUS).l
                bne.s   Int_VBlank_AcquireZ80BusForExit
                move.b  #0,(Z80VBlankActive).l
Int_VBlank_ReleaseZ80BusForExit:                        ; CODE XREF: VBLANK+90   j  ; was: loc_B02
                bclr    #0,(IO_Z80BUS).l
                beq.s   Int_VBlank_ReleaseZ80BusForExit
                move    #$2300,sr
                bsr.w   Sys_VBlankEventHandler
                movem.l (sp)+,d0-d7/a0-a5
                rte
; End of function VBLANK

; Extended VBlank interrupt handler that manages sound Z80 bus acquisition VDP updates and input processing
Sys_VBlankHandler:                                      ; CODE XREF: VBLANK+74   j  ; was: sub_B1A
                tst.w   (FrameSkipLevel).w
                beq.s   Sys_VBlankHandler_RunUpdate
                tst.b   (FrameControlFlags).w
                bmi.s   Sys_VBlankHandler_RunUpdate
                cmpi.w  #1,(VBlankFrameDivider).w
                beq.s   Int_VBlank_AcquireZ80BusForExit
Sys_VBlankHandler_RunUpdate:                            ; CODE XREF: Sys_VBlankHandler+4   j  ; was: loc_B2E
                                        ; Sys_VBlankHandler+A   j
                clr.b   (VBlankUpdateReady).w
                bsr.w   Input_PollBothControllersWithZ80BusLock
                bsr.w   Gfx_RunVBlankTransfers
                bsr.w   Gfx_ApplyVDPRegisterShadows
                jsr     (RasterBuffer_CopySelectedLayout).l
Sys_VBlankHandler_AcquireZ80BusForExit:                 ; CODE XREF: Sys_VBlankHandler+32   j  ; was: loc_B44
                bset    #0,(IO_Z80BUS).l
                bne.s   Sys_VBlankHandler_AcquireZ80BusForExit
                move.b  #0,(Z80VBlankActive).l
Sys_VBlankHandler_ReleaseZ80BusForExit:                 ; CODE XREF: Sys_VBlankHandler+44   j  ; was: loc_B56
                bclr    #0,(IO_Z80BUS).l
                beq.s   Sys_VBlankHandler_ReleaseZ80BusForExit
                move    #$2300,sr
                bsr.w   Sys_VBlankEventHandler
                bsr.w   Input_UpdatePauseFromStartButton
                jsr     (RandomNumber).l
                bsr.w   Sys_UpdateTimers
                move.b  #1,(VBlankUpdateReady).w
                movem.l (sp)+,d0-d7/a0-a5
                rte
; End of function Sys_VBlankHandler
; Toggles the pause flag and sound pause when Start is pressed on an enabled port
Input_UpdatePauseFromStartButton:                       ; CODE XREF: Sys_VBlankHandler+4E   p  ; was: sub_B82
                move.b  (GameplayControlFlags).w,d0
                btst    #6,d0
                beq.w   Input_UpdatePauseFromStartButton_Return
                clr.b   d1
                btst    #0,d0
                beq.w   Input_UpdatePauseFromStartButton_CheckPort2
                or.b    (ControllerPressedState).w,d1
Input_UpdatePauseFromStartButton_CheckPort2:            ; CODE XREF: Input_UpdatePauseFromStartButton+12   j  ; was: loc_B9C
                btst    #1,d0
                beq.w   Input_UpdatePauseFromStartButton_CheckStartPressed
                or.b    (ControllerPressedState+1).w,d1
Input_UpdatePauseFromStartButton_CheckStartPressed:     ; CODE XREF: Input_UpdatePauseFromStartButton+1E   j  ; was: loc_BA8
                tst.b   d1
                bpl.w   Input_UpdatePauseFromStartButton_Return
                tst.b   d0
                bmi.w   Input_UpdatePauseFromStartButton_Unpause
                bset    #7,d0
                move.b  d0,(GameplayControlFlags).w
                move.b  #1,(SoundPauseState).w
                rts
; ---------------------------------------------------------------------------
Input_UpdatePauseFromStartButton_Unpause:               ; CODE XREF: Input_UpdatePauseFromStartButton+2E   j  ; was: loc_BC4
                bclr    #7,d0
                move.b  d0,(GameplayControlFlags).w
                move.b  #$80,(SoundPauseState).w
Input_UpdatePauseFromStartButton_Return:                ; CODE XREF: Input_UpdatePauseFromStartButton+8   j  ; was: locret_BD2
                                        ; Input_UpdatePauseFromStartButton+28   j
                rts
; End of function Input_UpdatePauseFromStartButton
; Handles timed events and callbacks during VBlank
Sys_VBlankEventHandler:                                 ; CODE XREF: VBLANK+96   p  ; was: sub_BD4
                                        ; Sys_VBlankHandler+4A   p
                move.w  (VBlankSoundRequestDelay).w,d0
                beq.w   Sys_VBlankEventHandler_CheckInput
                subq.w  #1,d0
                move.w  d0,(VBlankSoundRequestDelay).w
                bra.w   Sys_VBlankEventHandler_UpdateSound
; ---------------------------------------------------------------------------
Sys_VBlankEventHandler_CheckInput:                      ; CODE XREF: Sys_VBlankEventHandler+4   j  ; was: loc_BE6
                move.b  (VBlankPendingSound).w,d0
                beq.w   Sys_VBlankEventHandler_UpdateSound
                jsr     (Sound_QueueRequest).l
                beq.w   Sys_VBlankEventHandler_UpdateSound
                clr.b   (VBlankPendingSound).w
Sys_VBlankEventHandler_UpdateSound:                     ; CODE XREF: Sys_VBlankEventHandler+E   j  ; was: loc_BFC
                                        ; Sys_VBlankEventHandler+16   j
                tst.b   (SoundUpdateBusy).w
                bne.w   Sys_VBlankEventHandler_Return
                move.b  #1,(SoundUpdateBusy).w
                jsr     (Sound_UpdateThunk).l
                if      BuildProfileEU
                addq.w  #1,(PALSoundCompensationCounter).w
                cmpi.w  #5,(PALSoundCompensationCounter).w
                bcs.s   Sys_VBlankEventHandler_ClearSoundBusy
                clr.w   (PALSoundCompensationCounter).w
                jsr     (Sound_UpdateThunk).l
                endif
Sys_VBlankEventHandler_ClearSoundBusy:
                clr.b   (SoundUpdateBusy).w
Sys_VBlankEventHandler_Return:                          ; CODE XREF: Sys_VBlankEventHandler+2C   j  ; was: locret_C14
                rts
; End of function Sys_VBlankEventHandler
; Updates the global countdown and advances the VBlank frame counter
Sys_UpdateTimers:                                       ; CODE XREF: Sys_VBlankHandler+58   p  ; was: sub_C16
                tst.w   (VBlankCountdown).w
                beq.s   Sys_UpdateTimers_AdvanceFrame
                subq.w  #1,(VBlankCountdown).w
Sys_UpdateTimers_AdvanceFrame:                          ; CODE XREF: Sys_UpdateTimers+4   j  ; was: loc_C20
                addq.w  #1,(VBlankFrameCounter).w
                bra.s   Sys_DispatchGameState_Run
; End of function Sys_UpdateTimers
; Checks game flags and dispatches to current game state handler via jump table
Sys_DispatchGameState:
                move.b  (GameplayControlFlags).w,d0     ; was: sub_C26
                bpl.w   Sys_DispatchGameState_Run
                btst    #6,d0
                beq.w   Sys_DispatchGameState_Run
                move.b  (ControllerHeldState).w,d0
                or.b    (ControllerHeldState+1).w,d0
                andi.b  #$70,d0                         ; 'p'
                cmpi.b  #$70,d0                         ; 'p'
                bne.w   Sys_DispatchGameState_Run
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.b  #4,(SoundRequestQueue).w
                clr.b   (SoundPauseState).w
                clr.w   (DataLoaderControl).w
                clr.w   (GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
Sys_DispatchGameState_Run:                              ; CODE XREF: Sys_UpdateTimers+E   j  ; was: loc_C6C
                                        ; Sys_DispatchGameState+4   j
                jsr     (Demo_PlaybackSystem).l
                move.w  (GameModeIndex).w,d0
                movea.l Sys_GameStateHandlers(pc,d0.w),a0
                jmp     (a0)
; ---------------------------------------------------------------------------
Sys_GameStateHandlers:  dc.l    Sys_CheckRegionLock     ; was: off_C7C
                dc.l    Frontend_InitializeSegaSequence
                dc.l    Frontend_UpdateOpeningSequence
                dc.l    Stage_UpdateGameplayEntry
                dc.l    Sys_GameplayMainLoop
                dc.l    TitleScreen_Initialize
                dc.l    TitleScreen_Update
                dc.l    UI_InitOptionsScreen
                dc.l    UI_UpdateOptionsScreen
                dc.l    StoryScreen_Initialize
                dc.l    StoryScreen_MainLoop
                dc.l    Results_InitializePostStageFlow
                dc.l    Results_DispatchPostStageState
                dc.l    StageTransition_Initialize
                dc.l    StageTransition_UpdateMessageScreen
                dc.l    StageReady_Initialize
                dc.l    StageReady_Update
                dc.l    PasswordMenu_Initialize
                dc.l    PasswordMenu_Update
                dc.l    UI_InitSecondaryOptionsMenu
                dc.l    UI_UpdateSecondaryOptionsMenu
                dc.l    Results_InitializeSecondaryOptionsReturn
                dc.l    RetryPrompt_Initialize
                dc.l    RetryPrompt_Update
                dc.l    Credits_InitializeScreen
                dc.l    Credits_UpdateFadeAndTransitionBuffers
                dc.l    Sys_TransitionToStageInit
                dc.l    Sys_StageTransitionUpdate
                dc.l    WeaponSetup_InitializeScreen
                dc.l    WeaponSetup_UpdateScreen
                dc.l    GameOver_InitializeScreen
                dc.l    GameOver_CopyTransitionBufferAndDispatch
                dc.l    XiTigerStage_UpdateGameplayEntry
                dc.l    Results_InitializeFinalSummary
                dc.l    Results_UpdateFinalSummary
                dc.l    Credits_InitXiTiger
                dc.l    Credits_MainLoop
; ---------------------------------------------------------------------------
                rts
; End of function Sys_DispatchGameState
; Performs VBlank DMA transfers for VRAM CRAM and VSRAM including sprite and scroll plane updates
