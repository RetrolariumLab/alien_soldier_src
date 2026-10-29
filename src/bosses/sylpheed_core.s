Boss_UpdateSylpheed:                                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_593D4
                tst.w   4(a5)
                beq.w   Boss_DispatchSylpheedState
                tst.w   8(a5)
                beq.s   Boss_DispatchSylpheedState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_UpdateSylpheedPaletteAndBounds
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_UpdateSylpheedPaletteAndBounds
                tst.w   (BossHealth).w
                bne.s   Boss_UpdateSylpheedPaletteAndBounds
                moveq   #6,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_UpdateSylpheedPaletteAndBounds:                    ; CODE XREF: Boss_UpdateSylpheed+14   j  ; was: loc_59400
                                        ; Boss_UpdateSylpheed+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #$24,d0                         ; '$'
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
                cmpi.w  #$1E0,$10(a5)
                bmi.s   Boss_ClampSylpheedLeftBoundary
                move.w  #$1DF,$10(a5)
                bra.s   Boss_DispatchSylpheedState
; ---------------------------------------------------------------------------
Boss_ClampSylpheedLeftBoundary:                         ; CODE XREF: Boss_UpdateSylpheed+46   j  ; was: loc_59424
                cmpi.w  #$A0,$10(a5)
                bpl.s   Boss_DispatchSylpheedState
                move.w  #$A1,$10(a5)
Boss_DispatchSylpheedState:                             ; CODE XREF: Boss_UpdateSylpheed+4   j  ; was: loc_59432
                                        ; Boss_UpdateSylpheed+C   j
                move.w  4(a5),d0
                movea.w Boss_SylpheedStateOffsets(pc,d0.w),a0
                adda.l  #Boss_InitSylpheed,a0
                jmp     (a0)
; End of function Boss_UpdateSylpheed
; ---------------------------------------------------------------------------
Boss_SylpheedStateOffsets:  dc.w    Boss_InitSylpheed-Boss_InitSylpheed  ; was: off_59442
                                        ; DATA XREF: Boss_UpdateSylpheed+62   r
                dc.w    Boss_RenderSylpheedInteractiveState2-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedDecisionState4-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedChargeState6-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedRecoveryState8-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedJumpRiseStateA-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedJumpFallStateC-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedDiveStateE-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedClimbState10-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedEntranceState12-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedEntrancePauseState14-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedPlayerTrackingState16-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedAttackApproachState18-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedAttackLaunchState1A-Boss_InitSylpheed
                dc.w    Boss_UpdateSylpheedAttackHoldState1C-Boss_InitSylpheed

; Initialize the live Sylpheed battle entity and enter state $12
Boss_InitSylpheed:                                      ; DATA XREF: Boss_UpdateSylpheed+66   o  ; was: sub_59460
                                        ; ROM:Boss_SylpheedStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$1A,d7
                movea.l #Boss_SylpheedMetaspritePartDescriptors,a0
                movea.l #Boss_SylpheedMetaspriteInitialAngles,a1
                movea.l #Boss_SylpheedMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_SylpheedMetaspritePoseAngles,$2FC(a5)
                move.l  #Sylpheed_PoseFrameData,$35C(a5)
                move.w  #$444,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  $14(a0),$14(a5)
                move.l  $18(a0),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                move.l  $1C(a0),$1C(a5)
                move.w  #2,$1DE(a5)
                bra.w   Boss_EnterSylpheedEntranceState12
; End of function Boss_InitSylpheed
; Initialize the statically unreferenced controller-driven state-$2 entry
Boss_InitSylpheedInteractiveState2:                     ; was: sub_594D0
                move.w  #2,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$1B58,(BossHealth).w
                move.w  #$1B58,(BossMaxHealth).w
                clr.w   (PlayerScriptStateOffset).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$80,$11C(a5)
; End of function Boss_InitSylpheedInteractiveState2
; Render controller-driven state $2 with its looping pose
Boss_RenderSylpheedInteractiveState2:                   ; DATA XREF: ROM:00059444   o  ; was: sub_59512
                lea     Sylpheed_InteractiveState2PoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_RenderSylpheedInteractiveState2
; Enter the opening descent state $12
Boss_EnterSylpheedEntranceState12:                      ; CODE XREF: Boss_InitSylpheed+6C   j  ; was: sub_5951C
                move.w  #$12,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  (Entity60XVel).w,$18(a5)
                move.l  (Entity60YVel).w,$1C(a5)
                move.w  #$FFE0,$50(a5)
                move.w  #$80,$56(a5)
                move.w  #$120,$3BC(a5)
                move.w  #$2E,(PlayerScriptStateOffset).w  ; '.'
; Continue opening descent state $12
Boss_UpdateSylpheedEntranceState12:                     ; DATA XREF: ROM:00059454   o  ; was: loc_5954E
                cmpi.w  #$10,$14(a5)
                bmi.s   Boss_EnterSylpheedEntrancePauseState14
                addq.w  #1,$50(a5)
                bmi.s   Boss_AccelerateSylpheedEntranceUpward
                clr.w   $50(a5)
Boss_AccelerateSylpheedEntranceUpward:                  ; CODE XREF: Boss_EnterSylpheedEntranceState12+3E   j  ; was: loc_59560
                subi.l  #$1000,$1C(a5)
                bsr.w   Boss_AdjustSylpheedHorizontalVelocityTowardTarget
                lea     Sylpheed_EntrancePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedEntrancePauseState14:                 ; CODE XREF: Boss_EnterSylpheedEntranceState12+38   j  ; was: loc_59576
                addq.w  #2,4(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #0,$14(a5)
                move.w  #$7000,(BossHealth).w
                move.w  #$7000,(BossMaxHealth).w
                clr.w   $50(a5)
                move.w  #$180,$56(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; Update the opening pause in state $14
Boss_UpdateSylpheedEntrancePauseState14:                ; DATA XREF: ROM:00059456   o  ; was: loc_595A4
                subq.w  #1,$11C(a5)
                bmi.s   Boss_EnterSylpheedPlayerTrackingState16
                lea     Sylpheed_EntrancePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedPlayerTrackingState16:                ; CODE XREF: Boss_EnterSylpheedEntranceState12+8C   j  ; was: loc_595B4
                addq.w  #2,4(a5)
                move.l  #$38000,$1C(a5)
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_EnterSylpheedEntranceState12
; Track the player while descending in state $16
Boss_UpdateSylpheedPlayerTrackingState16:               ; DATA XREF: ROM:00059458   o  ; was: sub_595CA
                move.w  (PlayerXPosition).w,$10(a5)
                move.w  (PlayerYPosition).w,d0
                subi.w  #$20,d0                         ; ' '
                cmp.w   $14(a5),d0
                bmi.w   Boss_EnterSylpheedAttackApproachState18
                lea     Sylpheed_EntrancePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedAttackApproachState18:                ; CODE XREF: Boss_UpdateSylpheedPlayerTrackingState16+12   j  ; was: loc_595EA
                addq.w  #2,4(a5)
                clr.l   $1C(a5)
                move.b  #1,(SceneSequenceFlags).w
                bclr    #4,(PlayerSpriteAttributes).w
                move.w  #$80,$11C(a5)
                move.b  #$2B,d0                         ; '+'
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_UpdateSylpheedPlayerTrackingState16
; Approach the attack anchor during state $18
Boss_UpdateSylpheedAttackApproachState18:               ; DATA XREF: ROM:0005945A   o  ; was: sub_5960E
                subq.w  #1,$11C(a5)
                bmi.w   Boss_EnterSylpheedAttackLaunchState1A
                bsr.w   Boss_MoveSylpheedTowardApproachHorizontalBand
                bsr.w   Boss_MoveSylpheedTowardApproachVerticalPosition
                move.w  $10(a5),(PlayerXPosition).w
                move.w  $14(a5),d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,(PlayerYPosition).w
                clr.l   (PlayerYVelocity).w
                lea     Sylpheed_EntrancePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_UpdateSylpheedAttackApproachState18
; Move horizontally toward the side-dependent approach band
Boss_MoveSylpheedTowardApproachHorizontalBand:          ; CODE XREF: Boss_UpdateSylpheedAttackApproachState18+8   p  ; was: sub_5963E
                cmpi.w  #$100,$10(a5)
                beq.s   Boss_MoveSylpheedApproachHorizontalReturn
                bpl.s   Boss_MoveSylpheedApproachLeftward
                addq.w  #4,$10(a5)
                cmpi.w  #$120,$10(a5)
                bpl.s   Boss_ClampSylpheedApproachHorizontalPosition
                rts
; ---------------------------------------------------------------------------
Boss_MoveSylpheedApproachLeftward:                      ; CODE XREF: Boss_MoveSylpheedTowardApproachHorizontalBand+8   j  ; was: loc_59656
                subq.w  #4,$10(a5)
                cmpi.w  #$120,$10(a5)
                bpl.s   Boss_MoveSylpheedApproachHorizontalReturn
Boss_ClampSylpheedApproachHorizontalPosition:           ; CODE XREF: Boss_MoveSylpheedTowardApproachHorizontalBand+14   j  ; was: loc_59662
                move.w  #$120,$10(a5)
Boss_MoveSylpheedApproachHorizontalReturn:              ; CODE XREF: Boss_MoveSylpheedTowardApproachHorizontalBand+6   j  ; was: locret_59668
                                        ; Boss_MoveSylpheedTowardApproachHorizontalBand+22   j
                rts
; End of function Boss_MoveSylpheedTowardApproachHorizontalBand
; Move vertically toward Y=$100
Boss_MoveSylpheedTowardApproachVerticalPosition:        ; CODE XREF: Boss_UpdateSylpheedAttackApproachState18+C   p  ; was: sub_5966A
                cmpi.w  #$100,$14(a5)
                beq.s   Boss_MoveSylpheedApproachVerticalReturn
                bpl.s   Boss_MoveSylpheedApproachUpward
                addq.w  #2,$14(a5)
                cmpi.w  #$100,$14(a5)
                bpl.s   Boss_ClampSylpheedApproachVerticalPosition
                rts
; ---------------------------------------------------------------------------
Boss_MoveSylpheedApproachUpward:                        ; CODE XREF: Boss_MoveSylpheedTowardApproachVerticalPosition+8   j  ; was: loc_59682
                subq.w  #2,$14(a5)
                cmpi.w  #$100,$14(a5)
                bpl.s   Boss_MoveSylpheedApproachVerticalReturn
Boss_ClampSylpheedApproachVerticalPosition:             ; CODE XREF: Boss_MoveSylpheedTowardApproachVerticalPosition+14   j  ; was: loc_5968E
                move.w  #$100,$14(a5)
Boss_MoveSylpheedApproachVerticalReturn:                ; CODE XREF: Boss_MoveSylpheedTowardApproachVerticalPosition+6   j  ; was: locret_59694
                                        ; Boss_MoveSylpheedTowardApproachVerticalPosition+22   j
                rts
; End of function Boss_MoveSylpheedTowardApproachVerticalPosition
; Enter the attack launch state $1A
Boss_EnterSylpheedAttackLaunchState1A:                  ; CODE XREF: Boss_UpdateSylpheedAttackApproachState18+4   j  ; was: sub_59696
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   (PlayerScriptStateOffset).w
                bset    #0,(PlayerModeFlags).w
                clr.w   (PlayerStateOffset).w
                move.b  #$20,(PlayerOAMBucketOffset).w  ; ' '
                move.l  #$FFFF0000,$18(a5)
                move.l  #$28000,$1C(a5)
; Accelerate through attack launch state $1A
Boss_UpdateSylpheedAttackLaunchState1A:                 ; DATA XREF: ROM:0005945C   o  ; was: loc_596CC
                addi.l  #$1000,$18(a5)
                subi.l  #$1000,$1C(a5)
                subi.w  #8,$56(a5)
                bmi.s   Boss_EnterSylpheedAttackHoldState1C
                lea     Sylpheed_AttackAndRecoveryPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedAttackHoldState1C:                    ; CODE XREF: Boss_EnterSylpheedAttackLaunchState1A+4C   j  ; was: loc_596EE
                addq.w  #2,4(a5)
                move.w  #$160,$3BC(a5)
                move.w  #$F0,$3BE(a5)
                movea.l #Boss_SylpheedObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #$40,$11C(a5)                   ; '@'
; Hold the attack formation during state $1C
Boss_UpdateSylpheedAttackHoldState1C:                   ; DATA XREF: ROM:0005945E   o  ; was: loc_59710
                subq.w  #1,$11C(a5)
                bpl.s   Boss_UpdateSylpheedAttackHoldMotion
                clr.b   (BossColorEffectFlags).w
                bclr    #0,(StageTimerPauseFlag).w
                move.w  #4,4(a5)
                bra.w   Boss_ArmSylpheedDecisionTimer
; ---------------------------------------------------------------------------
Boss_UpdateSylpheedAttackHoldMotion:                    ; CODE XREF: Boss_EnterSylpheedAttackLaunchState1A+7E   j  ; was: loc_5972A
                bsr.w   Boss_AdjustSylpheedVerticalVelocityTowardTarget
                lea     Sylpheed_AttackAndRecoveryPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_EnterSylpheedAttackLaunchState1A
; Enter the state-$4 decision loop and arm its difficulty-dependent timer
Boss_EnterSylpheedDecisionState4:                       ; CODE XREF: Boss_UpdateSylpheedJumpFallStateC+4   j  ; was: sub_59738
                                        ; Boss_UpdateSylpheedClimbState10+4   j
                move.w  #$60,$11E(a5)                   ; '`'
                tst.w   (DifficultyMode).w
                beq.s   Boss_ResetSylpheedDecisionState4
                move.w  #$40,$11E(a5)                   ; '@'
Boss_ResetSylpheedDecisionState4:                       ; CODE XREF: Boss_EnterSylpheedDecisionState4+A   j  ; was: loc_5974A
                                        ; Boss_UpdateSylpheedRecoveryState8+4   j
                move.w  #4,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_ArmSylpheedDecisionTimer:                          ; CODE XREF: Boss_EnterSylpheedAttackLaunchState1A+90   j  ; was: loc_5975E
                move.w  #$160,$3BC(a5)
                move.w  #$F0,$3BE(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$10,d0
                move.w  d0,$11C(a5)
; Update the state-$4 attack decision
Boss_UpdateSylpheedDecisionState4:                      ; DATA XREF: ROM:00059446   o  ; was: loc_5977A
                subq.w  #1,$11E(a5)
                bpl.s   Boss_RenderSylpheedDecisionPose
                move.w  #$FFFF,$11E(a5)
                tst.w   (DifficultyMode).w
                beq.s   Boss_CheckSylpheedForcedCharge
                cmpi.w  #$2858,(BossHealth).w
                bmi.s   Boss_CountDownSylpheedDecisionTimer
Boss_CheckSylpheedForcedCharge:                         ; CODE XREF: Boss_EnterSylpheedDecisionState4+52   j  ; was: loc_59794
                btst    #2,(PlayerActionStateFlags).w
                beq.s   Boss_CountDownSylpheedDecisionTimer
                bra.w   Boss_EnterSylpheedChargeState6
; ---------------------------------------------------------------------------
Boss_CountDownSylpheedDecisionTimer:                    ; CODE XREF: Boss_EnterSylpheedDecisionState4+5A   j  ; was: loc_597A0
                                        ; Boss_EnterSylpheedDecisionState4+62   j
                subq.w  #1,$11C(a5)
                bpl.s   Boss_RenderSylpheedDecisionPose
                btst    #0,(RandomNumberState).w
                beq.w   Boss_EnterSylpheedJumpRiseStateA
                bra.w   Boss_EnterSylpheedDiveStateE
; ---------------------------------------------------------------------------
Boss_RenderSylpheedDecisionPose:                        ; CODE XREF: Boss_EnterSylpheedDecisionState4+46   j  ; was: loc_597B4
                                        ; Boss_EnterSylpheedDecisionState4+6C   j
                bsr.w   Boss_RandomizeSylpheedTargetOffsets
                lea     Sylpheed_DecisionPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedChargeState6:                         ; CODE XREF: Boss_EnterSylpheedDecisionState4+64   j  ; was: loc_597C2
                move.w  #6,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$2C000,$18(a5)
; Update the forced charge in state $6
Boss_UpdateSylpheedChargeState6:                        ; DATA XREF: ROM:00059448   o  ; was: loc_597DA
                tst.w   $58(a5)
                bmi.w   Boss_EnterSylpheedRecoveryState8
                subi.l  #$1800,$18(a5)
                lea     Sylpheed_ChargePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedRecoveryState8:                       ; CODE XREF: Boss_EnterSylpheedDecisionState4+A6   j  ; was: loc_597F4
                addq.w  #2,4(a5)
                move.w  #$60,$11C(a5)                   ; '`'
                move.w  #$1D0,$3BC(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$F1,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_EnterSylpheedDecisionState4
; Update recovery state $8
Boss_UpdateSylpheedRecoveryState8:                      ; DATA XREF: ROM:0005944A   o  ; was: sub_59818
                subq.w  #1,$11C(a5)
                bmi.w   Boss_ResetSylpheedDecisionState4
                btst    #2,(PlayerActionStateFlags).w
                beq.s   Boss_UpdateSylpheedRecoveryTarget
                move.w  #$60,$11C(a5)                   ; '`'
Boss_UpdateSylpheedRecoveryTarget:                      ; CODE XREF: Boss_UpdateSylpheedRecoveryState8+E   j  ; was: loc_5982E
                bsr.w   Boss_RandomizeSylpheedTargetOffsets
                lea     Sylpheed_AttackAndRecoveryPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_UpdateSylpheedRecoveryState8
; Enter jump-rise state $A with its initial velocity
Boss_EnterSylpheedJumpRiseStateA:                       ; CODE XREF: Boss_EnterSylpheedDecisionState4+74   j  ; was: sub_5983C
                move.w  #$A,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$18000,$18(a5)
                move.l  #$C000,$1C(a5)
                move.b  #$DC,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_EnterSylpheedJumpRiseStateA
; Update jump-rise state $A
Boss_UpdateSylpheedJumpRiseStateA:                      ; DATA XREF: ROM:0005944C   o  ; was: sub_59866
                tst.w   $58(a5)
                bmi.w   Boss_EnterSylpheedJumpFallStateC
                subi.l  #$1C00,$18(a5)
                subi.l  #$E00,$1C(a5)
                lea     Sylpheed_JumpRisePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedJumpFallStateC:                       ; CODE XREF: Boss_UpdateSylpheedJumpRiseStateA+4   j  ; was: loc_59888
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_UpdateSylpheedJumpRiseStateA
; Update jump-fall state $C until the pose completes
Boss_UpdateSylpheedJumpFallStateC:                      ; DATA XREF: ROM:0005944E   o  ; was: sub_598A4
                tst.w   $58(a5)
                bmi.w   Boss_EnterSylpheedDecisionState4
                addi.l  #$1E00,$18(a5)
                addi.l  #$1600,$1C(a5)
                lea     Sylpheed_JumpFallPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_UpdateSylpheedJumpFallStateC
; Enter dive state $E with its initial velocity
Boss_EnterSylpheedDiveStateE:                           ; CODE XREF: Boss_EnterSylpheedDecisionState4+78   j  ; was: sub_598C6
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$18000,$18(a5)
                move.l  #$FFFF4000,$1C(a5)
                move.b  #$DC,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_EnterSylpheedDiveStateE
; Update dive state $E until the pose completes
Boss_UpdateSylpheedDiveStateE:                          ; DATA XREF: ROM:00059450   o  ; was: sub_598F0
                tst.w   $58(a5)
                bmi.w   Boss_EnterSylpheedClimbState10
                subi.l  #$1C00,$18(a5)
                addi.l  #$1200,$1C(a5)
                lea     Sylpheed_DivePoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; ---------------------------------------------------------------------------
Boss_EnterSylpheedClimbState10:                         ; CODE XREF: Boss_UpdateSylpheedDiveStateE+4   j  ; was: loc_59912
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_UpdateSylpheedDiveStateE
; Update climb state $10 until the pose completes
Boss_UpdateSylpheedClimbState10:                        ; DATA XREF: ROM:00059452   o  ; was: sub_5992E
                tst.w   $58(a5)
                bmi.w   Boss_EnterSylpheedDecisionState4
                addi.l  #$1E00,$18(a5)
                subi.l  #$1600,$1C(a5)
                lea     Sylpheed_ClimbPoseScript(pc),a1
                nop
                bra.w   Boss_RenderSylpheedPose
; End of function Boss_UpdateSylpheedClimbState10
; Periodically randomize the current movement-target offsets
Boss_RandomizeSylpheedTargetOffsets:                    ; CODE XREF: Boss_EnterSylpheedDecisionState4:Boss_RenderSylpheedDecisionPose   p  ; was: sub_59950
                                        ; sub_59818:Boss_UpdateSylpheedRecoveryTarget   p
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.s   Boss_AdjustSylpheedVerticalVelocityTowardTarget
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                move.w  d0,$41E(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                move.w  d0,$41C(a5)
; End of function Boss_RandomizeSylpheedTargetOffsets
; Adjust vertical velocity toward the jittered target
Boss_AdjustSylpheedVerticalVelocityTowardTarget:        ; CODE XREF: Boss_EnterSylpheedAttackLaunchState1A:Boss_UpdateSylpheedAttackHoldMotion   p  ; was: sub_5997A
                                        ; Boss_RandomizeSylpheedTargetOffsets+8   j
                move.w  $3BE(a5),d1
                add.w   $41E(a5),d1
                move.w  $14(a5),d0
                cmp.w   d1,d0
                bmi.s   Boss_CheckSylpheedDownwardVelocity
                tst.w   $1C(a5)
                bpl.s   Boss_AccelerateSylpheedUpward
                cmpi.l  #$FFFF0000,$1C(a5)
                bmi.s   Boss_AdjustSylpheedHorizontalVelocityTowardTarget
Boss_AccelerateSylpheedUpward:                          ; CODE XREF: Boss_AdjustSylpheedVerticalVelocityTowardTarget+14   j  ; was: loc_5999A
                subi.l  #$1000,$1C(a5)
                bra.s   Boss_AdjustSylpheedHorizontalVelocityTowardTarget
; ---------------------------------------------------------------------------
Boss_CheckSylpheedDownwardVelocity:                     ; CODE XREF: Boss_AdjustSylpheedVerticalVelocityTowardTarget+E   j  ; was: loc_599A4
                tst.w   $1C(a5)
                bmi.s   Boss_AccelerateSylpheedDownward
                cmpi.l  #$10000,$1C(a5)
                bpl.s   Boss_AdjustSylpheedHorizontalVelocityTowardTarget
Boss_AccelerateSylpheedDownward:                        ; CODE XREF: Boss_AdjustSylpheedVerticalVelocityTowardTarget+2E   j  ; was: loc_599B4
                addi.l  #$1000,$1C(a5)
; End of function Boss_AdjustSylpheedVerticalVelocityTowardTarget
; Adjust horizontal velocity toward the jittered target
Boss_AdjustSylpheedHorizontalVelocityTowardTarget:      ; CODE XREF: Boss_EnterSylpheedEntranceState12+4C   p  ; was: sub_599BC
                                        ; Boss_AdjustSylpheedVerticalVelocityTowardTarget+1E   j
                move.w  $3BC(a5),d1
                add.w   $41C(a5),d1
                move.w  $10(a5),d0
                cmp.w   d1,d0
                bmi.s   Boss_CheckSylpheedRightwardVelocity
                tst.w   $18(a5)
                bpl.s   Boss_AccelerateSylpheedLeftward
                cmpi.l  #$FFFF0000,$18(a5)
                bmi.s   Boss_AdjustSylpheedHorizontalVelocityReturn
Boss_AccelerateSylpheedLeftward:                        ; CODE XREF: Boss_AdjustSylpheedHorizontalVelocityTowardTarget+14   j  ; was: loc_599DC
                subi.l  #$800,$18(a5)
Boss_AdjustSylpheedHorizontalVelocityReturn:            ; CODE XREF: Boss_AdjustSylpheedHorizontalVelocityTowardTarget+1E   j  ; was: locret_599E4
                                        ; Boss_AdjustSylpheedHorizontalVelocityTowardTarget+38   j
                rts
; ---------------------------------------------------------------------------
Boss_CheckSylpheedRightwardVelocity:                    ; CODE XREF: Boss_AdjustSylpheedHorizontalVelocityTowardTarget+E   j  ; was: loc_599E6
                tst.w   $18(a5)
                bmi.s   Boss_AccelerateSylpheedRightward
                cmpi.l  #$10000,$18(a5)
                bpl.s   Boss_AdjustSylpheedHorizontalVelocityReturn
Boss_AccelerateSylpheedRightward:                       ; CODE XREF: Boss_AdjustSylpheedHorizontalVelocityTowardTarget+2E   j  ; was: loc_599F6
                addi.l  #$800,$18(a5)
                rts
; End of function Boss_AdjustSylpheedHorizontalVelocityTowardTarget
; Update the pose and render the Sylpheed metasprite
; End of Sylpheed state and movement subsystem
