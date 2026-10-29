; Spawns a type-A4 debris object around Shellshogun during defeat launch
Boss_ShellshogunSpawnDefeatDebris:                      ; CODE XREF: Boss_ShellshogunDefeatLaunchState:Boss_ShellshogunRenderDefeatLaunch   p  ; was: sub_3A122
                jsr     (Projectile_PrepareImpactSpawnAfterDelay).l
                bne.s   Boss_ShellshogunSpawnDefeatDebrisReturn
                jsr     (Sprite_InitTypeA4FromTable).l
                clr.b   $20(a0)
                move.l  $18(a5),$18(a0)
                move.l  $1C(a5),$1C(a0)
                neg.l   $18(a0)
                neg.l   $1C(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d0                         ; ' '
                subi.w  #$20,d1                         ; ' '
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_ShellshogunSpawnDefeatDebrisReturn:                ; CODE XREF: Boss_ShellshogunSpawnDefeatDebris+6   j  ; was: locret_3A170
                rts
; End of function Boss_ShellshogunSpawnDefeatDebris
; Interprets one pose-command stream and publishes its linked-part angles
Boss_ShellshogunUpdatePose:                             ; CODE XREF: Boss_ShellshogunDefeatLaunchState+B0   p  ; was: sub_3A172
                                        ; Boss_ShellshogunDecisionState+7A   p
                clr.w   $17C(a5)
                tst.w   $C(a5)
                bpl.s   Boss_ShellshogunAdvancePoseInterpolation
Boss_ShellshogunReadNextPoseCommand:                    ; CODE XREF: Boss_ShellshogunUpdatePose+2A   j  ; was: loc_3A17C
                move.w  $58(a5),d0
                bmi.s   Boss_ShellshogunPublishPoseAngles
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_ShellshogunCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunCheckPoseLoopCommand:                   ; CODE XREF: Boss_ShellshogunUpdatePose+18   j  ; was: loc_3A192
                cmpi.w  #$FFFF,d3
                bne.s   Boss_ShellshogunStartPoseInterpolation
                clr.w   $58(a5)
                bra.s   Boss_ShellshogunReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_ShellshogunStartPoseInterpolation:                 ; CODE XREF: Boss_ShellshogunUpdatePose+24   j  ; was: loc_3A19E
                addq.w  #4,$58(a5)
                subq.w  #1,$11E(a5)
                addq.w  #1,$17C(a5)
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_ShellshogunPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_ShellshogunCalculatePoseDeltas
                move.b  (PoseDurationByte).w,d1
                ext.w   d1
                add.w   d1,$C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_ShellshogunPublishPoseAngles
Boss_ShellshogunAdvancePoseInterpolation:               ; CODE XREF: Boss_ShellshogunUpdatePose+8   j  ; was: loc_3A1D4
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$E,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_ShellshogunPublishPoseAngles:                      ; CODE XREF: Boss_ShellshogunUpdatePose+E   j  ; was: loc_3A1E4
                                        ; Boss_ShellshogunUpdatePose+60   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
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
                move.b  $10(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                move.b  $14(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                move.w  d0,$3B6(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$416(a5)
                move.w  d1,$476(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$4D6(a5)
                move.b  $20(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$536(a5)
                move.b  $24(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                move.w  d0,$5F6(a5)
                move.b  $28(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  $2C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                move.b  $30(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$776(a5)
                move.w  d0,$7D6(a5)
                move.b  $34(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$836(a5)
                move.w  d1,$896(a5)
                move.b  $38(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$8F6(a5)
                rts
; End of function Boss_ShellshogunUpdatePose
; Calculates per-channel deltas toward Shellshogun's neutral pose
Boss_ShellshogunCalculatePoseDeltas:                    ; CODE XREF: Boss_ShellshogunUpdatePose+4E   p  ; was: sub_3A2CC
                movea.l #Boss_ShellshogunNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                subq.w  #1,$C(a5)
                moveq   #$E,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_ShellshogunCalculatePoseDeltas
; ---------------------------------------------------------------------------
Boss_ShellshogunDecisionPoses:  dc.w    $10, $F, $18, 0, $FFFF  ; was: word_3A2E6
                                        ; DATA XREF: ROM:Entity_UpdateHandlerTable   o
                                        ; Boss_ShellshogunDecisionState:Boss_ShellshogunUpdateDecisionPose   o
Boss_ShellshogunTimedStageAdvancePoses: dc.w    $F030, $1E, $70, $1E, $FFFE  ; was: word_3A2F0
                                        ; DATA XREF: Boss_ShellshogunDecisionState+CC   o
Boss_ShellshogunSlamPoses:  dc.w    $EF11, $5A, $E830, $87, $E, $87, $9080, $96, $12, $96, $9080, $87, $FFFE  ; was: word_3A2FA
                                        ; DATA XREF: Boss_ShellshogunUpdateSlamAnimation   o
Boss_ShellshogunSharedPoses:    dc.w    $17, $2D, $10, $3C, $1B, $4B, $21, $5A, $FFFF  ; was: word_3A314
                                        ; DATA XREF: Boss_ShellshogunUpdateSharedPose   o
Boss_ShellshogunJumpWindupPoses:    dc.w    $FE14, $69, 6, $69, $FE12, $78, 6, $78, $FFFF  ; was: word_3A326
                                        ; DATA XREF: Boss_ShellshogunJumpAttackWindupState:Boss_ShellshogunRenderJumpWindup   o
Boss_ShellshogunJumpAirPoses:           dc.w    $FE28, $F, $FFFE  ; DATA XREF: Boss_ShellshogunJumpAttackAirState:Boss_ShellshogunRenderJumpAir   o  ; was: word_3A338
Boss_ShellshogunDirectionalAttackPoses: dc.w    $FC18, $A6, $FD18, $A6, $13, $A6, $FF0E, $B5, $A, $B5, $D840, $A6, $FFFE  ; was: word_3A33E
                                        ; DATA XREF: Boss_ShellshogunDirectionalAttackWindupState:Boss_ShellshogunUpdateDirectionalAttackWindup   o
                                        ; Boss_ShellshogunDirectionalAttackMotionState:Boss_ShellshogunRenderDirectionalAttack   o
Boss_ShellshogunLeapPoses:  dc.w    $FC18, $E2, $FD18, $E2, $FE0E, $D3, $FF0E, $C4, $18, $C4, $16, $E2, $FFFE  ; was: word_3A358
                                        ; DATA XREF: Boss_ShellshogunLeapWindupState+6   o
                                        ; Boss_ShellshogunLeapFlightState:Boss_ShellshogunRenderLeapFlight   o
Boss_ShellshogunLeapRecoveryPoses:  dc.w    $FC0C, $E2, $18, $E2, $FC0C, $F, $FFFE  ; was: word_3A372
                                        ; DATA XREF: Boss_ShellshogunLeapRecoveryState+28   o
Boss_ShellshogunDefeatLaunchPoses:  dc.w    $C, $C4, $C, $E2, $FFFF  ; was: word_3A380
                                        ; DATA XREF: Boss_ShellshogunDefeatLaunchState+AA   o
Boss_ShellshogunPoseTable:  dc.w    $CCE8, $20E8, $2013, $FE2, $A870, $3060, $78B8, $4CC0, $E010, $F020, $1400, $F0A0, $7844, $6080, $BC40, $C0D0  ; was: word_3A38A
                                        ; DATA XREF: Boss_ShellshogunUpdatePose+46   o
                dc.w    $F0E0, $2020, $20C0, $B090, $2060, $60E0, $40CC, $E810, $F020, $F870, $F0A8, $7030, $5060, $F030, $D0E0, $20F8
                dc.w    $2010, $28C0, $B090, $5860, $70E8, $30CE, $E418, $FC20, $2840, $A0B8, $8018, $5090, $9010, $BCD4, $D0, $3030
                dc.w    $4090, $9C50, $1050, $50C0, $70C4, $D8C0, $C020, $848, $B4B8, $C040, $6078, $B84C, $BCE8, $5020, $3000, $44C0
                dc.w    $9828, $E050, $80BC, $40B0, $C0D0, $C000, $E070, $F090, $8020, $5050, $A090, $D800, $4000, $3010, $20C0, $B8A0
                dc.w    $6060, $6808, $1040, $B4D2, $5040, $2014, $F0, $9848, $A460, $78A8, $5CD8, $F000, $20, $1050, $A0B8, $A0D0
                dc.w    $6068, $810, $C0E0, $4040, $2020, $60C0, $A040, $C060, $60A0, $40C0, $D0D0, $F030, $3010, $C0B0, $B010, $5050
                dc.w    $F040, $C0E0, $20C0, $1000, $609C, $A060, $4070, $80A0, $64FF
