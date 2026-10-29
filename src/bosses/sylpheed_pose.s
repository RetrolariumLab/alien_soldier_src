; Sylpheed pose interpolation, part projection, and pose data
Boss_RenderSylpheedPose:                                ; was: sub_59A00
                                        ; Boss_EnterSylpheedEntranceState12+56   j
                bsr.w   Boss_UpdateSylpheedPoseScript
                bsr.w   Boss_ApplySylpheedPoseToParts
                moveq   #$19,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_RenderSylpheedPose
; Project the interpolated pose channels into Sylpheed part angles
Boss_ApplySylpheedPoseToParts:                          ; was: sub_59A10
                move.w  #$100,$416(a5)
                moveq   #0,d0
                move.b  (a0),d0
                asl.w   #1,d0
                moveq   #0,d1
                move.w  $20(a0),d1
                asl.l   #8,d1
                asl.l   #1,d1
                and.w   d7,d0
                move.w  d0,$B6(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$176(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                moveq   #0,d0
                move.b  4(a0),d0
                asl.w   #1,d0
                moveq   #0,d1
                move.w  $24(a0),d1
                asl.l   #8,d1
                asl.l   #1,d1
                and.w   d7,d0
                move.w  d0,$236(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$296(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                swap    d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$476(a5)
                move.b  $C(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$4D6(a5)
                move.w  d1,$536(a5)
                moveq   #0,d0
                move.b  $10(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                moveq   #0,d2
                move.w  $28(a0),d2
                asl.l   #8,d2
                asl.l   #1,d2
                and.w   d7,d0
                move.w  d0,$716(a5)
                addi.w  #$100,d0
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$5F6(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$656(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$6B6(a5)
                move.b  $14(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$776(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$7D6(a5)
                move.w  d1,$836(a5)
                moveq   #0,d0
                move.b  $1C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                moveq   #0,d2
                move.w  $2C(a0),d2
                asl.l   #8,d2
                asl.l   #1,d2
                and.w   d7,d0
                move.w  d0,$A16(a5)
                addi.w  #$100,d0
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$896(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$8F6(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$956(a5)
                swap    d0
                add.l   d2,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$9B6(a5)
                rts
; End of function Boss_ApplySylpheedPoseToParts
; Interpret the current Sylpheed pose script
Boss_UpdateSylpheedPoseScript:                          ; was: sub_59B72
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_AdvanceSylpheedPoseInterpolation
Boss_ReadSylpheedPoseScriptCommand:                     ; was: loc_59B7C
                                        ; Boss_LoadSylpheedPoseFrame+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_PrepareSylpheedPoseRender
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ProcessSylpheedPoseScriptEntry
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ReadSylpheedPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_ProcessSylpheedPoseScriptEntry:                    ; was: loc_59B98
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_LoadSylpheedPoseFrame
                move.w  d3,$58(a5)
                bra.w   Boss_PrepareSylpheedPoseRender
; End of function Boss_UpdateSylpheedPoseScript
; UNKNOWN CODE-004: no static entry path; see docs/unknowns.md
Boss_SylpheedPoseScriptUnreferencedReturn:              ; was: nullsub_135
                rts
; End of function Boss_SylpheedPoseScriptUnreferencedReturn

; Handle a pose loop command or begin a pose-frame interpolation
Boss_LoadSylpheedPoseFrame:                             ; was: sub_59BAC
                cmpi.w  #$FFFF,d3
                bne.s   Boss_StartSylpheedPoseFrame
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ReadSylpheedPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_StartSylpheedPoseFrame:                            ; was: loc_59BBC
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_CalculateSylpheedPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_PrepareSylpheedPoseRender
Boss_AdvanceSylpheedPoseInterpolation:                  ; was: loc_59BEC
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$B,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_PrepareSylpheedPoseRender:                         ; was: loc_59BFC
                                        ; Boss_UpdateSylpheedPoseScript+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Boss_LoadSylpheedPoseFrame
; Calculate interpolation deltas for the 12-channel pose buffer
Boss_CalculateSylpheedPoseInterpolation:                ; was: sub_59C06
                movea.l $2FC(a5),a1
                moveq   #$B,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_CalculateSylpheedPoseInterpolation
; Initialize the twelve-channel Sylpheed pose buffer from bytes at a0
Boss_SylpheedInitializePoseChannels:                    ; was: sub_59C1A
                moveq   #$B,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_SylpheedInitializePoseChannels
; ---------------------------------------------------------------------------
Sylpheed_InteractiveState2Poses:    dc.w    $2020, $18, $2020, $24, $FFFF  ; was: word_59C26
Sylpheed_EntrancePoses:             dc.w    $810, 0, $808, 0, $810, $C, $808, $C  ; was: word_59C30
                                        ; Boss_EnterSylpheedEntranceState12+8E   o
                dc.w    $FFFF
Sylpheed_AttackAndRecoveryPoses:    dc.w    $1060, $18, $3030, $18, $1060, $24, $3030, $24  ; was: word_59C42
                                        ; Boss_EnterSylpheedAttackLaunchState1A+98   o
                dc.w    $FFFF
Sylpheed_DecisionPoses: dc.w    $1060, $30, $3030, $30, $1060, $3C, $3030, $3C  ; was: word_59C54
                dc.w    $FFFF
Sylpheed_ChargePoses:   dc.w    $808, $18, $FFFE        ; was: word_59C66
Sylpheed_JumpRisePoses: dc.w    $810, $48, $2020, $48, $FFFE  ; was: word_59C6C
Sylpheed_JumpFallPoses: dc.w    $640, $54, $C0E, $54, $E0E, $54, $FFFE  ; was: word_59C76
Sylpheed_DivePoses:     dc.w    $810, $60, $2020, $60, $FFFE  ; was: word_59C84
Sylpheed_ClimbPoses:    dc.w    $640, $6C, $C0E, $6C, $E0E, $6C, $FFFE  ; was: word_59C8E
Sylpheed_PoseTable:     dc.w    $70F0, $50F8, $C0D0, $F840, $1010, $8F8, $9010, $3008  ; was: word_59C9C
                dc.w    $C0B0, $840, $F0F0, $8F8, $B020, $60F8, $A0A0, $860
                dc.w    $E014, $14EC, $A034, $5010, $A0B0, $F060, $E010, $EF2
                dc.w    $9000, $3810, $A0C8, $F060, $F012, $10F0, $8010, $40F0
                dc.w    $C0C0, $1040, $FE04, $8F8, $A840, $60A0, $A0E0, $6060
                dc.w    $E0E8, $18E8, $58F0, $E0D0, $C060, $E050, $E00C, $10F8
                dc.w    $5000, $20C8, $A098, $4060, $10F0, $12E8, $E048, $A402
                dc.w    $C000, $3838, $E0EC, $8F2, $8010, $7030, $B890, $D048
                dc.w    $D008, $10F0, $9020, $20E0, $C0E0, $2040, $F820, $4FC

; End of Sylpheed pose subsystem
