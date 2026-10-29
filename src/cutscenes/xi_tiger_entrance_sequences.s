; Dispatches Xi-Tiger's Stage 8 train entrance sequence
Cutscene_XiTigerTrainEntranceController:                ; was: sub_2EF32
                clr.w   6(a5)
                move.w  4(a5),d0
                lea     Cutscene_XiTigerTrainEntranceStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Cutscene_XiTigerTrainEntranceController
; ---------------------------------------------------------------------------
Cutscene_XiTigerTrainEntranceStateTable:    dc.w    Cutscene_XiTigerTrainEntranceInit-*  ; was: off_2EF42
                dc.w    Cutscene_XiTigerTrainEntranceWait-*
                dc.w    Cutscene_XiTigerTrainEntrancePrepareJump-*
                dc.w    Cutscene_XiTigerTrainEntranceSwitchAirbornePose-*
                dc.w    Cutscene_XiTigerTrainEntranceUpdateJump-*
                dc.w    Cutscene_XiTigerTrainEntranceFinish-*

; Initializes Xi-Tiger above the Stage 8 train roof
Cutscene_XiTigerTrainEntranceInit:                      ; was: sub_2EF4E
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                bsr.w   Cutscene_XiTigerActorSetup
                bset    #3,$E(a5)
                move.w  #$100,$10(a5)
                move.w  (PrimaryCameraYPosition).w,d0
                bsr.w   Cutscene_XiTigerAlignToTrainRoof
                move.l  #Cutscene_XiTigerEntranceGroundedMapping,8(a5)
                clr.w   $C(a5)
                rts
; End of function Cutscene_XiTigerTrainEntranceInit
; Loads the palette and common object parameters used by both entrances
Cutscene_XiTigerActorSetup:                             ; was: sub_2EF7E
                                        ; Cutscene_XiTigerBossEntranceInit+4   p
                lea     (XiTigerCutscenePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #$CD00,2(a5)
                move.w  #$E400,$E(a5)
                move.l  #$F010F808,$2C(a5)
                move.l  #$F010F808,$28(a5)
                move.b  #$C0,$21(a5)
                move.b  #$10,$23(a5)
                move.b  #$60,$20(a5)                    ; '`'
                rts
; End of function Cutscene_XiTigerActorSetup
; Keeps Xi-Tiger on the Stage 8 train roof while the vertical scroll changes
Cutscene_XiTigerAlignToTrainRoof:                       ; was: sub_2EFBA
                                        ; Cutscene_XiTigerTrainEntranceWait   p
                move.w  (PrimaryCameraYPosition).w,$14(a5)
                addi.w  #$A8,$14(a5)
                rts
; End of function Cutscene_XiTigerAlignToTrainRoof
; Holds the opening pose, then starts the pre-jump delay
Cutscene_XiTigerTrainEntranceWait:                      ; was: sub_2EFC8
                bsr.w   Cutscene_XiTigerAlignToTrainRoof
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerTrainEntranceWait_Return
                move.l  #Cutscene_XiTigerEntrancePreJumpAndLandingMapping,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Cutscene_XiTigerTrainEntranceWait_Return:               ; was: locret_2EFE8
                rts
; End of function Cutscene_XiTigerTrainEntranceWait
; Waits in the second pose, then launches Xi-Tiger up and to the left
Cutscene_XiTigerTrainEntrancePrepareJump:               ; was: sub_2EFEA
                bsr.w   Cutscene_XiTigerAlignToTrainRoof
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerTrainEntrancePrepareJump_Return
                move.l  #Cutscene_XiTigerEntranceGroundedMapping,8(a5)
                clr.w   $C(a5)
                move.l  #$FFFA0000,$1C(a5)
                move.w  #$FFFC,$18(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Cutscene_XiTigerTrainEntrancePrepareJump_Return:        ; was: locret_2F018
                rts
; End of function Cutscene_XiTigerTrainEntrancePrepareJump
; Changes to the airborne pose four frames after launch
Cutscene_XiTigerTrainEntranceSwitchAirbornePose:        ; was: sub_2F01A
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerTrainEntranceSwitchAirbornePose_Return
                move.l  #Cutscene_XiTigerEntranceAirborneMapping,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Cutscene_XiTigerTrainEntranceSwitchAirbornePose_Return:  ; was: locret_2F030
                rts
; End of function Cutscene_XiTigerTrainEntranceSwitchAirbornePose
; Applies gravity and detects Xi-Tiger landing after the train-roof jump
Cutscene_XiTigerTrainEntranceUpdateJump:                ; was: sub_2F032
                btst    #7,$1C(a5)
                bne.s   Cutscene_XiTigerTrainEntranceApplyGravity
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                bne.s   Cutscene_XiTigerTrainEntranceOnLanding
Cutscene_XiTigerTrainEntranceApplyGravity:              ; was: loc_2F048
                addi.l  #$4000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
; Stops the jump on landing and starts the departure delay
Cutscene_XiTigerTrainEntranceOnLanding:                 ; was: loc_2F052
                clr.l   $18(a5)
                move.w  #$80,$48(a5)
                move.l  #Cutscene_XiTigerEntranceGroundedMapping,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Cutscene_XiTigerTrainEntranceUpdateJump
; Removes Xi-Tiger, releases the stage gate, and restores the stage palette
Cutscene_XiTigerTrainEntranceFinish:                    ; was: sub_2F06E
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerTrainEntranceFinish_Return
                move.w  #$1000,2(a5)
                clr.w   (PlayerScriptStateOffset).w
                lea     (SharedStagePaletteCommand).l,a0
                jmp     Gfx_LoadPaletteCommand
; ---------------------------------------------------------------------------
Cutscene_XiTigerTrainEntranceFinish_Return:             ; was: locret_2F08A
                rts
; End of function Cutscene_XiTigerTrainEntranceFinish
; Dispatches Xi-Tiger's entrance immediately before his boss encounter
Cutscene_XiTigerBossEntranceController:                 ; was: sub_2F08C
                clr.w   6(a5)
                move.w  4(a5),d0
                lea     Cutscene_XiTigerBossEntranceStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Cutscene_XiTigerBossEntranceController
; ---------------------------------------------------------------------------
Cutscene_XiTigerBossEntranceStateTable: dc.w    Cutscene_XiTigerBossEntranceInit-*  ; was: off_2F09C
                dc.w    Cutscene_XiTigerBossEntranceWaitForScroll-*
                dc.w    Cutscene_XiTigerBossEntranceUpdateJump-*
                dc.w    Cutscene_XiTigerBossEntranceLandingDelay-*
                dc.w    Cutscene_XiTigerBossEntranceCycleLandingFrames-*
                dc.w    Cutscene_XiTigerBossEntranceHoldPose-*

; Initializes the boss-entrance actor below the current camera position
Cutscene_XiTigerBossEntranceInit:                       ; was: sub_2F0A8
                addq.w  #2,4(a5)
                bsr.w   Cutscene_XiTigerActorSetup
                bsr.w   Cutscene_XiTigerBossEntranceUpdateY
                move.w  #$60,$10(a5)                    ; '`'
                rts
; End of function Cutscene_XiTigerBossEntranceInit
; Keeps Xi-Tiger at the boss-entrance vertical offset from stage scroll
Cutscene_XiTigerBossEntranceUpdateY:                    ; was: sub_2F0BC
                                        ; Cutscene_XiTigerBossEntranceWaitForScroll+6   p
                move.w  (PrimaryCameraYPosition).w,$14(a5)
                addi.w  #$128,$14(a5)
                rts
; End of function Cutscene_XiTigerBossEntranceUpdateY
; Waits for the secondary camera X to go negative, then launches Xi-Tiger up
Cutscene_XiTigerBossEntranceWaitForScroll:              ; was: sub_2F0CA
                move.w  #$60,$10(a5)                    ; '`'
                bsr.w   Cutscene_XiTigerBossEntranceUpdateY
                tst.w   (SecondaryCameraXPos).w
                bpl.s   Cutscene_XiTigerBossEntranceWaitForScroll_Return
                move.l  #$FFFA0000,$1C(a5)
                move.w  #2,$18(a5)
                move.l  #Cutscene_XiTigerEntranceAirborneMapping,8(a5)
                addq.w  #2,4(a5)
Cutscene_XiTigerBossEntranceWaitForScroll_Return:       ; was: locret_2F0F4
                rts
; End of function Cutscene_XiTigerBossEntranceWaitForScroll
; Applies gravity and detects the boss-entrance landing
Cutscene_XiTigerBossEntranceUpdateJump:                 ; was: sub_2F0F6
                btst    #7,$1C(a5)
                bne.s   Cutscene_XiTigerBossEntranceApplyGravity
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                bne.s   Cutscene_XiTigerBossEntranceOnLanding
Cutscene_XiTigerBossEntranceApplyGravity:               ; was: loc_2F10C
                addi.l  #$4000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Cutscene_XiTigerBossEntranceOnLanding:                  ; was: loc_2F116
                clr.l   $18(a5)
                move.l  #Cutscene_XiTigerEntrancePreJumpAndLandingMapping,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Cutscene_XiTigerBossEntranceUpdateJump
; Holds the landing pose, then starts the two-frame sound animation
Cutscene_XiTigerBossEntranceLandingDelay:               ; was: sub_2F132
                bsr.w   Cutscene_XiTigerBossEntranceUpdateY
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerBossEntranceLandingDelay_Return
                move.l  #Cutscene_XiTigerEntranceGroundedMapping,8(a5)
                clr.w   $C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
                move.b  #$20,d0                         ; ' '
                jsr     (Sound_QueueSFXRequest).l
Cutscene_XiTigerBossEntranceLandingDelay_Return:        ; was: locret_2F160
                rts
; End of function Cutscene_XiTigerBossEntranceLandingDelay
; Plays the two landing frames and advances to the held pose
Cutscene_XiTigerBossEntranceCycleLandingFrames:         ; was: sub_2F162
                bsr.w   Cutscene_XiTigerBossEntranceUpdateY
                subq.w  #1,$48(a5)
                bne.s   Cutscene_XiTigerBossEntranceCycleLandingFrames_Return
                move.w  $4A(a5),d0
                lsl.w   #2,d0
                move.l  Cutscene_XiTigerBossEntranceLandingFrameTable(pc,d0.w),8(a5)
                clr.w   $C(a5)
                move.w  #4,$48(a5)
                addq.w  #1,$4A(a5)
                cmpi.w  #2,$4A(a5)
                bne.s   Cutscene_XiTigerBossEntranceCycleLandingFrames_Return
                addq.w  #2,4(a5)
Cutscene_XiTigerBossEntranceCycleLandingFrames_Return:  ; was: locret_2F192
                                        ; Cutscene_XiTigerBossEntranceCycleLandingFrames+2A   j
                rts
; End of function Cutscene_XiTigerBossEntranceCycleLandingFrames
; ---------------------------------------------------------------------------
Cutscene_XiTigerBossEntranceLandingFrameTable:  dc.l    Cutscene_XiTigerEntranceLandingMappingA  ; was: off_2F194
                dc.l    Cutscene_XiTigerEntranceLandingMappingB

; Holds Xi-Tiger at the stage-relative boss-entrance position
Cutscene_XiTigerBossEntranceHoldPose:                   ; was: sub_2F19C
                bsr.w   Cutscene_XiTigerBossEntranceUpdateY
                rts
; End of function Cutscene_XiTigerBossEntranceHoldPose
