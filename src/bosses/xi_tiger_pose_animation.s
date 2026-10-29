; Interprets pose commands, advances 16 interpolation channels, and applies their angles
Boss_XiTigerUpdatePoseAnimation:                        ; was: sub_3E21C
                                        ; Boss_XiTigerBattleStart+2C   p
                clr.w   $29C(a5)
                tst.w   $C(a5)
                bpl.s   Boss_XiTigerAdvancePoseInterpolation
Boss_XiTigerReadPoseCommand:                            ; was: loc_3E226
                move.w  $58(a5),d0
                bmi.w   Boss_XiTigerApplyPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_XiTigerDecodePoseCommand
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_XiTigerDecodePoseCommand:                          ; was: loc_3E248
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_XiTigerCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_XiTigerCheckPoseLoopCommand:                       ; was: loc_3E258
                cmpi.w  #$FFFF,d3
                bne.s   Boss_XiTigerBeginPoseCommand
                clr.w   $58(a5)
                clr.w   $A(a5)
                bra.s   Boss_XiTigerReadPoseCommand
; ---------------------------------------------------------------------------
Boss_XiTigerBeginPoseCommand:                           ; was: loc_3E268
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_XiTigerPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_XiTigerBeginPoseInterpolation
                move.b  (PoseDurationByte).w,d1
                ext.w   d1
                add.w   d1,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$A(a5)
                addq.w  #1,$29C(a5)
                subq.w  #1,$17E(a5)
                tst.w   $C(a5)
                bmi.s   Boss_XiTigerApplyPoseAngles
Boss_XiTigerAdvancePoseInterpolation:                   ; was: loc_3E2A2
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$F,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_XiTigerApplyPoseAngles:                            ; was: loc_3E2B2
                                        ; Boss_XiTigerUpdatePoseAnimation+84   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  $3C(a0),d6
                asl.w   #1,d6
                move.w  d6,d0
                addi.w  #$80,d0
                and.w   d7,d0
                move.w  d0,$4D6(a5)
                move.b  4(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$176(a5)
                move.w  d0,$1D6(a5)
                move.b  $C(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$236(a5)
                move.w  d1,$296(a5)
                move.b  $10(a0),d1
                asl.w   #1,d1
                add.w   d6,d1
                and.w   d7,d1
                move.w  d1,$536(a5)
                move.b  $14(a0),d0
                asl.w   #1,d0
                and.w   d7,d1
                move.w  d0,$596(a5)
                move.w  d0,$5F6(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                move.b  $20(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                move.b  $24(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                move.w  d0,$3B6(a5)
                move.b  $28(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$416(a5)
                move.w  d1,$476(a5)
                move.b  $2C(a0),d1
                asl.w   #1,d1
                add.w   d6,d1
                and.w   d7,d1
                move.w  d1,$776(a5)
                move.b  $30(a0),d0
                asl.w   #1,d0
                and.w   d7,d1
                move.w  d0,$7D6(a5)
                move.w  d0,$836(a5)
                move.b  $34(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$896(a5)
                move.w  d1,$8F6(a5)
                move.b  $38(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$956(a5)
                rts
; End of function Boss_XiTigerUpdatePoseAnimation
; Begins interpolation from the current channels to the selected pose target
Boss_XiTigerBeginPoseInterpolation:                     ; was: sub_3E3B0
                movea.l #Boss_XiTigerNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #$F,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_XiTigerBeginPoseInterpolation
; Initializes all 16 Xi-Tiger pose channels from bytes at a0
Boss_XiTigerInitializePoseChannels:                     ; was: sub_3E3C6
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                moveq   #$F,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_XiTigerInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_XiTigerIdlePoses:  dc.w    $F510, 0, $15, 0, $80DC, $F510, $10, $15, $10, $80DC, $FFFF  ; was: word_3E3D2
                                        ; Boss_XiTigerEnterIdleState:Boss_XiTigerUpdateIdlePose   o
Boss_XiTigerLandingRecoveryPoses:   dc.w    $F810, $70, $C, $70, $FFFE  ; was: word_3E3E8
                                        ; Boss_XiTigerJumpDescendAndLand:Boss_XiTigerUpdateLandingRecoveryPose   o
Boss_XiTigerDashRecoveryPoses:  dc.w    $FC08           ; was: word_3E3F2
                dc.w    $20, $12, $20, $FFFE
Boss_XiTigerCloseRangeAttackPoses:  dc.w    $F810, $20, 3, $20, $F50E, $30, 4, $30, $F810, $20, 3, $20, $F511, $40, 4, $40  ; was: word_3E3FC
                dc.w    $F810, $20, 3, $20, $F510, $50, 4, $50, $FFFF
Boss_XiTigerDashPreparationPoses:   dc.w    $F414, $80, $16, $80  ; was: word_3E42E
                dc.w    $8880, $90, $FE10, $90, $10, $90, $FFFE
Boss_XiTigerCloseRangeJumpPreparationPoses: dc.w    $F410, $70, $18, $70, $FC0C, $A0, $C, $A0, $FFFE  ; was: word_3E444
Boss_XiTigerAirbornePoses:                  dc.w    $CA40, $B0, $FE0C, $B0, 8, $B0, $FFFE  ; was: word_3E456
                                        ; Boss_XiTigerJumpRise:Boss_XiTigerUpdateJumpAirbornePose   o
Boss_XiTigerLoopingAirbornePoses:   dc.w    $C, $A0, $C, $B0, $FFFF  ; was: word_3E464
                                        ; Boss_XiTigerDefeatLeapState:Boss_XiTigerUpdateDefeatLeapPose   o
Boss_XiTigerDefeatPoses:    dc.w    $E220, $C0, $E120, $70, $FFFF  ; was: word_3E46E
                                        ; Boss_XiTigerDefeatFadeState:Boss_XiTigerUpdateDefeatFadePose   o
Boss_XiTigerBattleStartPoses:   dc.w    $F058, $D0, $38, $D0, $EC50, $C0, $D040, $C0, $ED18, $10, $14, $10, $FFFE  ; was: word_3E478
Boss_XiTigerPoseTable:          dc.w    $C8EC, $3860, $1038, $38F0, $8C50, $AC70, $6400, $E0FA, $D4F8, $3050, $1014, $1018, $9640, $9870, $50C0, $606  ; was: word_3E492
                dc.w    $C4E4, $B470, $1010, $4000, $9080, $3070, $6EF8, $D0FA, $D600, $2000, $800, $5000, $A090, $5070, $6EF0, $D00C
                dc.w    $D608, $3010, $1008, $4000, $A090, $6060, $6008, $D00C, $DA06, $1800, $F8F4, $6000, $9490, $4080, $70F8, $C00C
                dc.w    $CCE8, $2038, $808, $6000, $9688, $F060, $38D0, $20FC
Boss_XiTigerInitialPoseChannels:    dc.w    $D0F8, $60, $10E0, $6000, $8880, $A070, $A0A0, 0, $D000, $6860, $1000, $1000, $8830, $C090, $A0A0, $F0  ; was: word_3E502
                dc.w    $C0E0, $C0C0, $1010, $4000, $8080, $A050, $6400, $E010, $C0D0, $C060, 0, $6030, $8070, $AC70, $5800, $D8F8
                dc.w    $D808, $2800, $1040, $40E0, $A0B0, $C070, $6010, $D80A, $C800, $40E0, $1030, $10, $8040, $2070, $5000, $F000
                dc.w    $C8F0, $5050, $1030, $10, $9030, $B070, $5000, $F000, $D0F6, $5450, $1830, $410, $8A2C, $B068, $50FC, $F000
