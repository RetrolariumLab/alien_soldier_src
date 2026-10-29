; Antroid pose interpolation, animation helpers, and command streams

; Interpolates animation values toward the next command target
Boss_AntroidUpdatePoseAnimation:                        ; CODE XREF: Boss_AntroidIdleState+6   p  ; was: sub_3811A
                                        ; Boss_AntroidReturnToNeutral+36   p
                clr.w   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_AntroidAdvancePoseInterpolation
Boss_AntroidReadPoseCommand:                            ; CODE XREF: Boss_AntroidUpdatePoseAnimation+4A   j  ; was: loc_38124
                move.w  $58(a5),d0
                bmi.w   Boss_AntroidApplyPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_AntroidDecodePoseCommand
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_AntroidDecodePoseCommand:                          ; CODE XREF: Boss_AntroidUpdatePoseAnimation+18   j  ; was: loc_38146
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_AntroidCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_AntroidCheckPoseLoopCommand:                       ; CODE XREF: Boss_AntroidUpdatePoseAnimation+34   j  ; was: loc_38156
                cmpi.w  #$FFFF,d3
                bne.s   Boss_AntroidBeginPoseCommand
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_AntroidReadPoseCommand
; ---------------------------------------------------------------------------
Boss_AntroidBeginPoseCommand:                           ; CODE XREF: Boss_AntroidUpdatePoseAnimation+40   j  ; was: loc_38166
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_AntroidPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_AntroidBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                addq.w  #1,$23E(a5)
                tst.w   $C(a5)
                bmi.s   Boss_AntroidApplyPoseAngles
Boss_AntroidAdvancePoseInterpolation:                   ; CODE XREF: Boss_AntroidUpdatePoseAnimation+8   j  ; was: loc_3819C
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$E,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_AntroidApplyPoseAngles:                            ; CODE XREF: Boss_AntroidUpdatePoseAnimation+E   j  ; was: loc_381AC
                                        ; Boss_AntroidUpdatePoseAnimation+80   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$116(a5)
                move.b  8(a0),d3
                asl.w   #1,d3
                and.w   d7,d3
                move.w  d3,$176(a5)
                movea.w #(SharedScratchLong3-M68K_RAM),a0
                movea.w #(SharedScratchLong6-M68K_RAM),a1
                movea.w #(SharedScratchLong9-M68K_RAM),a2
                movea.w #(SharedScratchLong12-M68K_RAM),a3
                tst.w   6(a5)
                beq.s   Boss_AntroidApplySidePoseAngles
                exg     a0,a1
                exg     a2,a3
Boss_AntroidApplySidePoseAngles:                        ; CODE XREF: Boss_AntroidUpdatePoseAnimation+D2   j  ; was: loc_381F2
                move.b  (a0),d2
                asl.w   #1,d2
                add.w   d0,d2
                and.w   d7,d2
                move.w  d2,$1D6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$236(a5)
                move.w  d1,$296(a5)
                move.b  8(a0),d2
                asl.w   #1,d2
                add.w   d1,d2
                and.w   d7,d2
                move.w  d2,$2F6(a5)
                move.w  d2,$356(a5)
                move.b  (a1),d2
                asl.w   #1,d2
                add.w   d0,d2
                and.w   d7,d2
                move.w  d2,$5F6(a5)
                move.b  4(a1),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  8(a1),d2
                asl.w   #1,d2
                add.w   d1,d2
                and.w   d7,d2
                move.w  d2,$716(a5)
                move.w  d2,$776(a5)
                move.b  (a2),d0
                asl.w   #1,d0
                add.w   d3,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                move.w  d0,$416(a5)
                move.w  d0,$476(a5)
                move.b  4(a2),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$4D6(a5)
                move.w  d1,$536(a5)
                move.b  8(a2),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                move.b  (a3),d0
                asl.w   #1,d0
                add.w   d3,d0
                and.w   d7,d0
                move.w  d0,$7D6(a5)
                move.w  d0,$836(a5)
                move.w  d0,$896(a5)
                move.b  4(a3),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$8F6(a5)
                move.w  d1,$956(a5)
                move.b  8(a3),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$9B6(a5)
                rts
; End of function Boss_AntroidUpdatePoseAnimation
; Begins interpolation from the current channels to the selected pose target
Boss_AntroidBeginPoseInterpolation:                     ; CODE XREF: Boss_AntroidUpdatePoseAnimation+62   p  ; was: sub_382BC
                movea.l #Boss_AntroidNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #$E,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_AntroidBeginPoseInterpolation
; Initializes all 15 Antroid pose channels from bytes at a0
Boss_AntroidInitializePoseChannels:
                movea.w #(SharedScratchLong0-M68K_RAM),a1  ; was: sub_382D2
                moveq   #$E,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_AntroidInitializePoseChannels
; Adjusts base Y so the higher of two linked parts reaches coordinate $14C
Boss_AntroidAdjustBaseYFromLinkedParts:
                move.w  $974(a5),d0                     ; was: sub_382DE
                move.w  $554(a5),d1
                cmp.w   d0,d1
                bpl.s   Boss_AntroidAdjustBaseYApply
                move.w  d0,d1
Boss_AntroidAdjustBaseYApply:                           ; CODE XREF: Boss_AntroidAdjustBaseYFromLinkedParts+A   j  ; was: loc_382EC
                move.w  #$14C,d0
                sub.w   d1,d0
                add.w   d0,$14(a5)
                rts
; End of function Boss_AntroidAdjustBaseYFromLinkedParts
; Toggles the active side and swaps its paired pose-channel groups
Boss_AntroidSwapPoseSides:                              ; CODE XREF: Boss_AntroidLeapAttackA:Boss_AntroidLeapAttackAFinish   p  ; was: sub_382F8
                                        ; Boss_AntroidLeapAttackA+74   p
                eori.w  #2,6(a5)
                movea.w #(SharedScratchLong3-M68K_RAM),a0
                movea.w #(SharedScratchLong6-M68K_RAM),a1
                movea.w #(SharedScratchLong9-M68K_RAM),a2
                movea.w #(SharedScratchLong12-M68K_RAM),a3
                moveq   #2,d7
; Swaps one longword in each paired pose-channel group
Boss_AntroidSwapPoseChannelGroups:                      ; CODE XREF: Boss_AntroidSwapPoseSides+24   j  ; was: loc_38310
                move.l  (a0),d0
                move.l  (a1),(a0)+
                move.l  d0,(a1)+
                move.l  (a2),d0
                move.l  (a3),(a2)+
                move.l  d0,(a3)+
                dbf     d7,Boss_AntroidSwapPoseChannelGroups
                rts
; End of function Boss_AntroidSwapPoseSides
; ---------------------------------------------------------------------------
Boss_AntroidIdlePoses:  dc.w    $2020, $60, $2020, $70, $FFFF  ; was: word_38322
                                        ; DATA XREF: Boss_AntroidIdleState   o
Boss_AntroidReturnPoses:    dc.w    $131B, $70, $FFFE   ; DATA XREF: Boss_AntroidReturnToNeutral+30   o  ; was: word_3832C
                                        ; sub_379AA:Boss_AntroidJumpAttackAnimateLandingArc   o
Boss_AntroidDecisionAPoses: dc.w    $80C, $60, $808, $60, $80C, $70, $808, $70, $FFFF  ; was: word_38332
                                        ; DATA XREF: Boss_AntroidReturnToNeutral:Boss_AntroidUpdateDecisionAnimation   o
Boss_AntroidDecisionBPoses: dc.w    $204, $60, $202, $60, $204, $70, $202, $70, $FFFF  ; was: word_38344
                                        ; DATA XREF: Boss_AntroidReturnToNeutral+FC   o
Boss_AntroidHealthRecoveryPoses:    dc.w    $214, $E0, $106, $60, $FFFF  ; was: word_38356
                                        ; DATA XREF: Boss_AntroidHealthRecoveryState+E   o
Boss_AntroidLeapAttackAPoses:   dc.w    $1313, $30, $A1E, $40, $2828, $40, $FFFE  ; was: word_38360
                                        ; DATA XREF: Boss_AntroidPrepareLeapAttackA:Boss_AntroidPrepareLeapAttackAAnimate   o
                                        ; sub_377F6:Boss_AntroidLeapAttackAAnimate   o
Boss_AntroidLeapAttackBPoses:   dc.w    $1313, $50, $A1E, $20, $2828, $20, $FFFE  ; was: word_3836E
                                        ; DATA XREF: Boss_AntroidPrepareLeapAttackB:Boss_AntroidPrepareLeapAttackBAnimate   o
                                        ; sub_378BE:Boss_AntroidLeapAttackBAnimate   o
Boss_AntroidJumpAttackPoses:    dc.w    $910, $90, $D0D, $90, $80D0, $80B, $A0, $410, $A0, $1010, $B0, $FFFE  ; was: word_3837C
                                        ; DATA XREF: Boss_AntroidPrepareJumpAttack+8   o
                                        ; sub_379AA:Boss_AntroidJumpAttackAnimateAirborne   o
Boss_AntroidJumpSlamRetryPoses: dc.w    $60A, $90, $505, $90, $80B, $A0  ; was: word_38394
                                        ; DATA XREF: Boss_AntroidJumpSlamAttack+202   o
Boss_AntroidJumpSlamFirstArcPoses:  dc.w    $910, $90, $F0F, $90, $410, $C0, $C0C, $C0, $1313, $E0, $FFFE  ; was: word_383A0
                                        ; DATA XREF: Boss_AntroidJumpSlamAttack+8   o
                                        ; sub_37A94:Boss_AntroidJumpSlamAnimateFirstArc   o
Boss_AntroidJumpSlamDecelerationPoses:  dc.w    $608, $F0, $E0E, $F0, $FFFE  ; was: word_383B6
                                        ; DATA XREF: Boss_AntroidJumpSlamAttack+104   o
Boss_AntroidJumpSlamSecondArcPoses: dc.w    $C0C, $D0, $606, $D0, $E0E, $E0, $FFFE  ; was: word_383C0
                                        ; DATA XREF: Boss_AntroidJumpSlamAttack:Boss_AntroidJumpSlamAnimateSecondArc   o
Boss_AntroidJumpSlamImpactPoses:    dc.w    $808, $E0, $FFFE  ; DATA XREF: Boss_AntroidJumpSlamAttack+1D2   o  ; was: word_383CE
Boss_AntroidWaitPoses:              dc.w    $181C, $100, $A0A, $100, $608, $110, $FFFE  ; was: word_383D4
                                        ; DATA XREF: Boss_AntroidWaitState+6   o
Boss_AntroidWaitFiringPoses:    dc.w    $203, $110, $130, $60, $80A9, $FFFF  ; was: word_383E2
                                        ; DATA XREF: Boss_AntroidWaitState+72   o
Boss_AntroidRamPoses:   dc.w    $808, 0, $808, $10, $FFFF  ; was: word_383EE
                                        ; DATA XREF: Boss_AntroidUpdateRamAttackPose+4   o
Boss_AntroidPoseTable:  binclude "data/other/word_383F8.bin"  ; was: word_383F8
Boss_AntroidPoseTargetsEnd:                             ; was: word_383F8_End

; Main Terobuster boss handler with state dispatch
