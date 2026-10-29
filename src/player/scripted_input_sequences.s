; Clears player input, runs the selected scripted-state handler, merges its
; generated held/pressed buttons, and expires the scripted-input interval
Player_UpdateScriptedInput:                             ; was: sub_199F4
                bsr.s   Player_DispatchScriptedInputState
                move.b  $6A(a5),d0
                or.b    d0,$69(a5)
                subq.w  #1,(ScriptedInputTimeout).w
                bpl.s   Player_UpdateScriptedInput_Return
                move.w  #$FFFF,(ScriptedInputTimeout).w
                clr.w   (ScriptedInputActive).w
Player_UpdateScriptedInput_Return:                      ; was: locret_19A0E
                rts
; End of function Player_UpdateScriptedInput

; Dispatches the even byte offset in PlayerScriptStateOffset through the shared player
; script table after rebuilding the player's world-space X coordinate
Player_DispatchScriptedInputState:                      ; was: sub_19A10
                clr.b   $69(a5)
                clr.b   $6A(a5)
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,(ScriptedPlayerWorldX).w
                move.w  (PlayerScriptStateOffset).w,d0
                movea.w PlayerScript_StateHandlerOffsets(pc,d0.w),a0
                adda.l  #PlayerScript_InitializePostSniperHoneyviperRunState02,a0
                jmp     (a0)
; End of function Player_DispatchScriptedInputState
; ---------------------------------------------------------------------------
PlayerScript_StateHandlerOffsets:   dc.w    PlayerScript_NoOpAndSharedReturn-PlayerScript_InitializePostSniperHoneyviperRunState02  ; was: off_19A34
                dc.w    PlayerScript_InitializePostSniperHoneyviperRunState02-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_InitializePostTerobusterRunState04-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForStatusClearState06-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForRunDelayState08-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_MoveRightPastTargetState0A-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_HoldRightCThenAdvanceState0C-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_FinishRunAtScreenX200State0E-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForStatusThenResumeRunState10-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_HoldBState12-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_NoOpAndSharedReturn-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_BeginFlyingNeoApproachState16-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_MoveToFlyingNeoTargetState18-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_InitializeFlyingNeoEntryState1A-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_UpdateFlyingNeoEntryState1C-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_FinishFlyingNeoEntryState1E-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForXiTigerIntroState20-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_InitializePostBugmaxRunState22-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForStatusClearState06-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForRunDelayState08-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_MoveRightPastPostBugmaxTargetState28-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_FinishPostBugmaxRunAtScreenX200State2A-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_WaitForPostBugmaxStatusState2C-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_EmitUpCWhenStatusBit6SetState2E-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_StartViblackPlayerState30-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_InitializePostJampanRunState32-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_FaceRightAndEmitUpCState34-PlayerScript_InitializePostSniperHoneyviperRunState02
                dc.w    PlayerScript_FaceLeftAndEmitUpCState36-PlayerScript_InitializePostSniperHoneyviperRunState02

; Initialize the post-Sniper Honeyviper scripted run toward world X $1BF8
PlayerScript_InitializePostSniperHoneyviperRunState02:  ; was: sub_19A6C
                                        ; ROM:PlayerScript_StateHandlerOffsets   o
                move.w  #$1BF8,(ScriptedInputTargetX).w
                move.w  #$16,(ScriptedInputDelay).w
                move.w  #6,(PlayerScriptStateOffset).w
                clr.b   (GameplayControlFlags).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$100,(ScriptedInputTimeout).w
                rts
; End of function PlayerScript_InitializePostSniperHoneyviperRunState02
; Initialize the post-Terobuster scripted run toward world X $12C0
PlayerScript_InitializePostTerobusterRunState04:        ; was: sub_19A90
                move.w  #$12C0,(ScriptedInputTargetX).w
                move.w  #$16,(ScriptedInputDelay).w
                move.w  #6,(PlayerScriptStateOffset).w
                clr.b   (GameplayControlFlags).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$100,(ScriptedInputTimeout).w
                rts
; End of function PlayerScript_InitializePostTerobusterRunState04
; Initialize the post-Jampan scripted run toward world X $1640
PlayerScript_InitializePostJampanRunState32:            ; was: sub_19AB4
                move.w  #$1640,(ScriptedInputTargetX).w
                move.w  #$16,(ScriptedInputDelay).w
                move.w  #6,(PlayerScriptStateOffset).w
                clr.b   (GameplayControlFlags).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$100,(ScriptedInputTimeout).w
                bset    #1,(PlayerRestrictionFlags).w
                bset    #0,(PlayerRestrictionFlags).w
                rts
; End of function PlayerScript_InitializePostJampanRunState32
; Initialize the post-Bugmax scripted run toward world X $0690
PlayerScript_InitializePostBugmaxRunState22:            ; was: sub_19AE4
                move.w  #$690,(ScriptedInputTargetX).w
                addq.w  #2,(PlayerScriptStateOffset).w
                clr.b   (GameplayControlFlags).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$100,(ScriptedInputTimeout).w
                bset    #1,(PlayerRestrictionFlags).w
                bset    #0,(PlayerRestrictionFlags).w
                rts
; End of function PlayerScript_InitializePostBugmaxRunState22
; Emit a synthetic C-button press for the current scripted frame
PlayerScript_EmitCPress:                                ; was: sub_19B0C
                                        ; PlayerScript_MoveToFlyingNeoTargetState18+2A   j
                move.b  #$20,$6A(a5)                    ; ' '
                rts
; End of function PlayerScript_EmitCPress
; Wait for player status flags to clear, then face right and start the run delay
PlayerScript_WaitForStatusClearState06:                 ; was: sub_19B14
                                        ; ROM:00019A58   o
                btst    #6,(PlayerActionStateFlags).w
                bne.s   PlayerScript_EmitCPress
                tst.b   (PlayerActionStateFlags).w
                bne.s   PlayerScript_NoOpAndSharedReturn
                addq.w  #2,(PlayerScriptStateOffset).w
                move.w  #$20,(ScriptedInputStepTimer).w  ; ' '
                bset    #3,$E(a5)
; Return from cutscene wait start
PlayerScript_NoOpAndSharedReturn:                       ; was: locret_19B32
                                        ; PlayerScript_MoveToFlyingNeoTargetState18+36   j
                rts
; End of function PlayerScript_WaitForStatusClearState06
; Wait for the scripted run delay, then advance to target movement
PlayerScript_WaitForRunDelayState08:                    ; was: sub_19B34
                                        ; ROM:00019A5A   o
                subq.w  #1,(ScriptedInputStepTimer).w
                bpl.s   PlayerScript_WaitForRunDelayState08_Return
                addq.w  #2,(PlayerScriptStateOffset).w
PlayerScript_WaitForRunDelayState08_Return:             ; was: locret_19B3E
                rts
; End of function PlayerScript_WaitForRunDelayState08
; Hold Right until world-space player X passes the configured target
PlayerScript_MoveRightPastTargetState0A:                ; was: sub_19B40
                btst    #1,(PlayerWallContactFlags).w
                beq.s   PlayerScript_MoveRightPastTargetState0A_MoveRight
                move.w  #$10,(PlayerScriptStateOffset).w
                move.b  #$20,$6A(a5)                    ; ' '
                rts
; ---------------------------------------------------------------------------
PlayerScript_MoveRightPastTargetState0A_MoveRight:      ; was: loc_19B56
                move.b  #8,$69(a5)
                btst    #0,(PlayerActionStateFlags).w
                bne.s   PlayerScript_MoveRightPastTargetState0A_Return
                move.w  (ScriptedInputTargetX).w,d0
                cmp.w   (ScriptedPlayerWorldX).w,d0
                bpl.s   PlayerScript_MoveRightPastTargetState0A_Return
                addq.w  #2,(PlayerScriptStateOffset).w
                move.b  #$20,$6A(a5)                    ; ' '
                move.w  (ScriptedInputDelay).w,(ScriptedInputStepTimer).w
PlayerScript_MoveRightPastTargetState0A_Return:         ; was: locret_19B7E
                                        ; PlayerScript_MoveRightPastTargetState0A+2C   j
                rts
; End of function PlayerScript_MoveRightPastTargetState0A
; Hold Right+C through the run delay, then emit Down+Right+C and advance
PlayerScript_HoldRightCThenAdvanceState0C:              ; was: sub_19B80
                move.b  #$28,$69(a5)                    ; '('
                subq.w  #1,(ScriptedInputStepTimer).w
                bpl.s   PlayerScript_HoldRightCThenAdvanceState0C_Return
                addq.w  #2,(PlayerScriptStateOffset).w
                move.b  #$2A,$69(a5)                    ; '*'
                move.b  #$20,$6A(a5)                    ; ' '
                bset    #1,(PlayerRestrictionFlags).w
                bset    #0,(PlayerRestrictionFlags).w
                bset    #7,(PlayerRestrictionFlags).w
PlayerScript_HoldRightCThenAdvanceState0C_Return:       ; was: locret_19BAE
                rts
; End of function PlayerScript_HoldRightCThenAdvanceState0C
; Hold Right+C until player screen X reaches $0200, then end scripted input
PlayerScript_FinishRunAtScreenX200State0E:              ; was: sub_19BB0
                bclr    #5,$6A(a5)
                move.b  #$28,$69(a5)                    ; '('
                cmpi.w  #$200,$10(a5)
                bmi.s   PlayerScript_FinishRunAtScreenX200State0E_Return
                move.w  #$200,$10(a5)
                clr.w   2(a5)
                clr.w   (ScriptedInputActive).w
PlayerScript_FinishRunAtScreenX200State0E_Return:       ; was: locret_19BD2
                rts
; End of function PlayerScript_FinishRunAtScreenX200State0E
; Hold Right+C until status clears, then resume the target run at state $0A
PlayerScript_WaitForStatusThenResumeRunState10:         ; was: sub_19BD4
                move.b  #$28,$69(a5)                    ; '('
                btst    #6,(PlayerActionStateFlags).w
                beq.s   PlayerScript_WaitForStatusThenResumeRunState10_CheckStatusClear
                move.b  #$28,$6A(a5)                    ; '('
PlayerScript_WaitForStatusThenResumeRunState10_CheckStatusClear:  ; was: loc_19BE8
                tst.b   (PlayerActionStateFlags).w
                bne.s   PlayerScript_WaitForStatusThenResumeRunState10_Return
                move.w  #$A,(PlayerScriptStateOffset).w
PlayerScript_WaitForStatusThenResumeRunState10_Return:  ; was: locret_19BF4
                rts
; End of function PlayerScript_WaitForStatusThenResumeRunState10
; Post-Bugmax variant: hold Right until world X passes $0690
PlayerScript_MoveRightPastPostBugmaxTargetState28:      ; was: sub_19BF6
                btst    #1,(PlayerWallContactFlags).w
                beq.s   PlayerScript_MoveRightPastPostBugmaxTargetState28_MoveRight
                move.w  #$2C,(PlayerScriptStateOffset).w  ; ','
                move.b  #$20,$6A(a5)                    ; ' '
                rts
; ---------------------------------------------------------------------------
PlayerScript_MoveRightPastPostBugmaxTargetState28_MoveRight:  ; was: loc_19C0C
                move.b  #8,$69(a5)
                btst    #0,(PlayerActionStateFlags).w
                bne.s   PlayerScript_MoveRightPastPostBugmaxTargetState28_Return
                move.w  (ScriptedInputTargetX).w,d0
                cmp.w   (ScriptedPlayerWorldX).w,d0
                bpl.s   PlayerScript_MoveRightPastPostBugmaxTargetState28_Return
                addq.w  #2,(PlayerScriptStateOffset).w
                move.b  #$22,$6A(a5)                    ; '"'
PlayerScript_MoveRightPastPostBugmaxTargetState28_Return:  ; was: locret_19C2E
                                        ; PlayerScript_MoveRightPastPostBugmaxTargetState28+2C   j
                rts
; End of function PlayerScript_MoveRightPastPostBugmaxTargetState28
; Finish the post-Bugmax run when player screen X reaches $0200
PlayerScript_FinishPostBugmaxRunAtScreenX200State2A:    ; was: sub_19C30
                cmpi.w  #$200,$10(a5)
                bmi.s   PlayerScript_FinishPostBugmaxRunAtScreenX200State2A_Return
                move.w  #$200,$10(a5)
                clr.w   2(a5)
                clr.w   (ScriptedInputActive).w
PlayerScript_FinishPostBugmaxRunAtScreenX200State2A_Return:  ; was: locret_19C46
                rts
; End of function PlayerScript_FinishPostBugmaxRunAtScreenX200State2A
; Wait for post-Bugmax status to clear, then resume state $28
PlayerScript_WaitForPostBugmaxStatusState2C:            ; was: sub_19C48
                move.b  #$28,$69(a5)                    ; '('
                btst    #0,(PlayerActionStateFlags).w
                bne.s   PlayerScript_WaitForPostBugmaxStatusState2C_Return
                move.w  #$28,(PlayerScriptStateOffset).w  ; '('
PlayerScript_WaitForPostBugmaxStatusState2C_Return:     ; was: locret_19C5C
                rts
; End of function PlayerScript_WaitForPostBugmaxStatusState2C
; Start the scripted Flying Neo approach and enable its player-control flags
PlayerScript_BeginFlyingNeoApproachState16:             ; was: sub_19C5E
                addq.w  #2,(PlayerScriptStateOffset).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$100,(ScriptedInputTimeout).w
                bset    #4,(PlayerRestrictionFlags).w
                btst    #4,$E(a5)
                beq.s   PlayerScript_MoveToFlyingNeoTargetState18
                move.b  #$20,$6A(a5)                    ; ' '
; Move horizontally toward world X $1040 and end the script once status clears
PlayerScript_MoveToFlyingNeoTargetState18:              ; was: loc_19C82
                btst    #6,(PlayerActionStateFlags).w
                bne.w   PlayerScript_EmitCPress
                move.w  #$1040,d0
                bsr.w   PlayerScript_SelectHorizontalInputTowardTarget
                bne.w   PlayerScript_NoOpAndSharedReturn
                tst.b   (PlayerActionStateFlags).w
                bne.w   PlayerScript_NoOpAndSharedReturn
                clr.w   (ScriptedInputActive).w
                rts
; End of function PlayerScript_BeginFlyingNeoApproachState16
; Initialize the Flying Neo player-entry motion and advance to state $1C
PlayerScript_InitializeFlyingNeoEntryState1A:           ; was: sub_19CA6
                addq.w  #2,(PlayerScriptStateOffset).w
                move.w  #2,(ScriptedInputActive).w
                move.w  #$200,(ScriptedInputTimeout).w
                bset    #0,(PlayerRestrictionFlags).w
                bset    #5,(PlayerRestrictionFlags).w
                move.w  #$148,$10(a5)
                bclr    #3,$E(a5)
                move.w  #$8000,(GlobalSpritePriorityBit).w
                bset    #3,$E(a5)
                move.b  #$20,$6A(a5)                    ; ' '
                bclr    #0,2(a5)
                move.w  #$E,(ScriptedInputDelay).w
; Move the player left while driving the timed vertical entry motion
PlayerScript_UpdateFlyingNeoEntryState1C:               ; was: loc_19CEC
                subi.l  #$28000,$10(a5)
                move.b  #$20,$69(a5)                    ; ' '
                subq.w  #1,(ScriptedInputDelay).w
                bmi.s   PlayerScript_UpdateFlyingNeoEntryState1C_WaitForVerticalMotionEnd
                move.l  #$FFF90000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
PlayerScript_UpdateFlyingNeoEntryState1C_WaitForVerticalMotionEnd:  ; was: loc_19D0A
                tst.l   $1C(a5)
                bmi.w   PlayerScript_NoOpAndSharedReturn
                bset    #0,2(a5)
                addq.w  #2,(PlayerScriptStateOffset).w
                clr.b   (PlayerRestrictionFlags).w
; Finish the Flying Neo player entry once the shared status byte clears
PlayerScript_FinishFlyingNeoEntryState1E:               ; was: loc_19D20
                subi.l  #$28000,$10(a5)
                tst.b   (PlayerActionStateFlags).w
                bne.w   PlayerScript_NoOpAndSharedReturn
                clr.w   (PlayerScriptStateOffset).w
                clr.w   (ScriptedInputActive).w
                move.l  #$FFFEE000,(StageMotionXDelta).w
                rts
; End of function PlayerScript_InitializeFlyingNeoEntryState1A
; Wait for the Xi-Tiger intro delay, then disable scripted input
PlayerScript_WaitForXiTigerIntroState20:                ; was: sub_19D42
                subq.w  #1,(ScriptedInputStepTimer).w
                bpl.s   PlayerScript_WaitForXiTigerIntroState20_Return
                clr.w   (PlayerScriptStateOffset).w
PlayerScript_WaitForXiTigerIntroState20_Return:         ; was: locret_19D4C
                rts
; End of function PlayerScript_WaitForXiTigerIntroState20
; Start player state $48 once the Viblack readiness word clears
PlayerScript_StartViblackPlayerState30:                 ; was: sub_19D4E
                tst.w   (PlayerDefeatPhase).w
                bne.s   PlayerScript_StartViblackPlayerState30_Return
                move.w  #$48,(PlayerStateOffset).w      ; 'H'
PlayerScript_StartViblackPlayerState30_Return:          ; was: locret_19D5A
                rts
; End of function PlayerScript_StartViblackPlayerState30
; Hold the B button while scripted-input state $12 is active
PlayerScript_HoldBState12:                              ; was: sub_19D5C
                move.b  #$10,$69(a5)
                rts
; End of function PlayerScript_HoldBState12
; Face right, then share state $2E's conditional Up+C input
PlayerScript_FaceRightAndEmitUpCState34:                ; was: sub_19D64
                bset    #3,$E(a5)
                bra.s   PlayerScript_EmitUpCWhenStatusBit6SetState2E
; End of function PlayerScript_FaceRightAndEmitUpCState34
; Face left, then share state $2E's conditional Up+C input
PlayerScript_FaceLeftAndEmitUpCState36:                 ; was: sub_19D6C
                bclr    #3,$E(a5)
; End of function PlayerScript_FaceLeftAndEmitUpCState36
; Emit Up+C while player-status bit six is set
PlayerScript_EmitUpCWhenStatusBit6SetState2E:           ; was: sub_19D72
                btst    #6,(PlayerActionStateFlags).w
                beq.s   PlayerScript_EmitUpCWhenStatusBit6SetState2E_Return
                move.b  #$21,$6A(a5)                    ; '!'
PlayerScript_EmitUpCWhenStatusBit6SetState2E_Return:    ; was: locret_19D80
                rts
; End of function PlayerScript_EmitUpCWhenStatusBit6SetState2E
; Select Left or Right until the world-X target is within six pixels
PlayerScript_SelectHorizontalInputTowardTarget:         ; was: sub_19D82
                sub.w   (ScriptedPlayerWorldX).w,d0
                move.w  d0,d1
                bpl.s   PlayerScript_SelectHorizontalInputTowardTarget_CompareDistance
                neg.w   d0
PlayerScript_SelectHorizontalInputTowardTarget_CompareDistance:  ; was: loc_19D8C
                cmpi.w  #6,d0
                bpl.s   PlayerScript_SelectHorizontalInputTowardTarget_Move
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
PlayerScript_SelectHorizontalInputTowardTarget_Move:    ; was: loc_19D96
                move.w  d1,d1
                bmi.s   PlayerScript_SelectHorizontalInputTowardTarget_MoveLeft
                bset    #3,$69(a5)
                moveq   #1,d0
                rts
; ---------------------------------------------------------------------------
PlayerScript_SelectHorizontalInputTowardTarget_MoveLeft:  ; was: loc_19DA4
                bset    #2,$69(a5)
                moveq   #1,d0
                rts
; End of function PlayerScript_SelectHorizontalInputTowardTarget
