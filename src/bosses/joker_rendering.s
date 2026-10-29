; Positions Joker's linked parts and prepares its rasterized tile display
Boss_JokerRenderBody:                                   ; CODE XREF: Boss_JokerUpdatePhaseGatePose+98   p  ; was: sub_3BA1A
                                        ; Boss_JokerUpdateDefeatDescent+30   j
                movea.w #(TwentiethEntityType-M68K_RAM),a0
                movea.w #(TwentySecondEntityType-M68K_RAM),a1
                movea.w #(TwentyFirstEntityType-M68K_RAM),a2
                movea.w #(TwentyThirdEntityType-M68K_RAM),a3
                tst.w   $54(a5)
                beq.s   Boss_JokerPositionLinkedParts
                exg     a0,a1
                exg     a2,a3
Boss_JokerPositionLinkedParts:                          ; CODE XREF: Boss_JokerRenderBody+14   j  ; was: loc_3BA34
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                move.w  #$FFE4,$40(a0)
                move.w  #$10,$44(a0)
                move.w  #$1C,$40(a1)
                move.w  #$10,$44(a1)
                move.w  $1DC(a5),d5
                subi.w  #$40,d5                         ; '@'
                asr.w   #1,d5
                addi.w  #$24,d5                         ; '$'
                move.w  #$FFE3,$40(a2)
                move.w  d5,$44(a2)
                move.w  #$1D,$40(a3)
                move.w  d5,$44(a3)
                moveq   #$15,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                cmpi.w  #$60,$10(a5)                    ; '`'
                bmi.s   Boss_JokerUseFixedHorizontalOffset
                cmpi.w  #$1E0,$10(a5)
                bmi.s   Boss_JokerUseScreenRelativeHorizontalOffset
Boss_JokerUseFixedHorizontalOffset:                     ; CODE XREF: Boss_JokerRenderBody+6A   j  ; was: loc_3BA8E
                move.w  #$FE72,(SecondaryCameraXPos).w
                bra.s   Boss_JokerInitializeDescendingWordRamp
; ---------------------------------------------------------------------------
Boss_JokerUseScreenRelativeHorizontalOffset:            ; CODE XREF: Boss_JokerRenderBody+72   j  ; was: loc_3BA96
                move.w  #$C0,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
Boss_JokerInitializeDescendingWordRamp:                 ; CODE XREF: Boss_JokerRenderBody+7A   j  ; was: loc_3BAA2
                move.w  #$80,d0
                move.w  #$5F,d7                         ; '_'
                movea.w #(BossPerspectiveRows-M68K_RAM),a0
Boss_JokerInitializeDescendingWordRampNextWord:         ; CODE XREF: Boss_JokerRenderBody+98   j  ; was: loc_3BAAE
                move.w  d0,(a0)+
                subq.w  #2,d0
                dbf     d7,Boss_JokerInitializeDescendingWordRampNextWord
                moveq   #0,d5
                move.w  $1DC(a5),d5
                subi.w  #$40,d5                         ; '@'
                beq.s   Boss_JokerBuildBodyHeightRasterValues
                ext.l   d5
                asl.l   #8,d5
                divs.w  $1DC(a5),d5
                swap    d5
                move.w  #0,d5
                asr.l   #8,d5
                asl.l   #1,d5
Boss_JokerBuildBodyHeightRasterValues:                  ; CODE XREF: Boss_JokerRenderBody+A6   j  ; was: loc_3BAD4
                moveq   #0,d3
                move.w  #$1B0,d3
                sub.w   $14(a5),d3
                move.l  d3,d4
                move.w  $14(a5),d0
                subi.w  #$98,d0
                addi.w  #-$6AE0,d0
                bclr    #0,d0
                movea.w d0,a0
                movea.w d0,a1
                moveq   #$1E,d7
Boss_JokerBuildBodyHeightRasterValuesNextPair:          ; CODE XREF: Boss_JokerRenderBody+EC   j  ; was: loc_3BAF6
                move.w  d3,-(a0)
                move.w  d4,(a1)+
                swap    d3
                add.l   d5,d3
                swap    d3
                swap    d4
                sub.l   d5,d4
                swap    d4
                dbf     d7,Boss_JokerBuildBodyHeightRasterValuesNextPair
                movea.w #(JokerTileWordGroupA-M68K_RAM),a0
                movea.w #(JokerTileWordGroupB-M68K_RAM),a1
                lea     Boss_JokerCyclingTileWords(pc),a2
                nop
                move.w  (FrameCounter).w,d0
                andi.w  #$1C,d0
                move.w  (a2,d0.w),d1
                move.w  2(a2,d0.w),d2
                move.w  $20(a2,d0.w),d3
                move.w  $22(a2,d0.w),d4
                move.w  d1,8(a0)
                move.w  d2,$A(a0)
                addi.w  #$800,d1
                addi.w  #$800,d2
                move.w  d2,4(a0)
                move.w  d1,6(a0)
                move.w  d3,8(a1)
                move.w  d4,$A(a1)
                addi.w  #$800,d3
                addi.w  #$800,d4
                move.w  d4,4(a1)
                move.w  d3,6(a1)
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_JokerUpdateSecondaryTileFrameIndex
                eori.w  #1,$29E(a5)
Boss_JokerUpdateSecondaryTileFrameIndex:                ; CODE XREF: Boss_JokerRenderBody+14E   j  ; was: loc_3BB70
                move.w  $29C(a5),d0
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_JokerApplySecondaryTileFrame
                tst.w   $29E(a5)
                bne.w   Boss_JokerIncreaseSecondaryTileFrameIndex
                subq.w  #4,d0
                bpl.s   Boss_JokerApplySecondaryTileFrame
                moveq   #0,d0
                bra.s   Boss_JokerApplySecondaryTileFrame
; ---------------------------------------------------------------------------
Boss_JokerIncreaseSecondaryTileFrameIndex:              ; CODE XREF: Boss_JokerRenderBody+166   j  ; was: loc_3BB8C
                addq.w  #4,d0
                cmpi.w  #$10,d0
                bmi.s   Boss_JokerApplySecondaryTileFrame
                moveq   #$C,d0
Boss_JokerApplySecondaryTileFrame:                      ; CODE XREF: Boss_JokerRenderBody+160   j  ; was: loc_3BB96
                                        ; Boss_JokerRenderBody+16C   j
                move.w  d0,$29C(a5)
                lea     Boss_JokerSecondaryTileFrameWords(pc),a2
                nop
                move.w  (a2,d0.w),d1
                move.w  2(a2,d0.w),d2
                move.w  $10(a2,d0.w),d3
                move.w  $12(a2,d0.w),d4
                move.w  d1,$C(a0)
                move.w  d2,$E(a0)
                addi.w  #$800,d1
                addi.w  #$800,d2
                move.w  d2,(a0)
                move.w  d1,2(a0)
                move.w  d3,$C(a1)
                move.w  d4,$E(a1)
                addi.w  #$800,d3
                addi.w  #$800,d4
                move.w  d4,(a1)
                move.w  d3,2(a1)
                move.l  #$8F02977F,d0
                move.l  #$94009308,d1
                movea.w (VDPCommandQueueHead).w,a4
                move.w  #$83,-(a4)
                move.w  #$6188,-(a4)
                move.w  #$9500,-(a4)
                move.w  #$96CB,-(a4)
                move.l  d0,-(a4)
                move.l  d1,-(a4)
                move.w  #$83,-(a4)
                move.w  #$6208,-(a4)
                move.w  #$9508,-(a4)
                move.w  #$96CB,-(a4)
                move.l  d0,-(a4)
                move.l  d1,-(a4)
                move.w  a4,(VDPCommandQueueHead).w
                rts
; End of function Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerCyclingTileWords: dc.w    $E302, $E303, $E32E, $E330, $E332, $E334, $E336, $E338  ; was: word_3BC1A
                                        ; DATA XREF: Boss_JokerRenderBody+F8   o
                dc.w    $E336, $E338, $E332, $E334, $E32E, $E330, $E302, $E303
                dc.w    $E306, $E307, $E32F, $E331, $E333, $E335, $E337, $E339
                dc.w    $E337, $E339, $E333, $E335, $E32F, $E331, $E306, $E307
Boss_JokerSecondaryTileFrameWords:  dc.w    $E342, $E344, $E33E, $E340, $E33A, $E33C, $E304, $E305  ; was: word_3BC5A
                                        ; DATA XREF: Boss_JokerRenderBody+180   o
                dc.w    $E343, $E345, $E33F, $E341, $E33B, $E33D, $E308, $E309

; Derives Joker's Y coordinate from its current fixed-point body height
Boss_JokerDeriveYFromBodyHeight:                        ; CODE XREF: Boss_JokerJumpAscentState:Boss_JokerUpdateBodyHeightCompressionPose   p  ; was: sub_3BC7A
                                        ; Boss_JokerJumpAscentState+A4   p
                move.w  $1DC(a5),d0
                subi.w  #$40,d0                         ; '@'
                asr.w   #1,d0
                addi.w  #$C8,d0
                move.w  d0,$14(a5)
                rts
; End of function Boss_JokerDeriveYFromBodyHeight
; Slows Joker boss horizontal velocity towards zero with fixed rate
Boss_JokerSlowHorizontalVelocity:                       ; CODE XREF: Boss_JokerStretchState:Boss_JokerUpdateStretchPose   p  ; was: sub_3BC8E
                move.l  $18(a5),d0
                beq.s   Boss_JokerSlowHorizontalVelocityReturn
                bmi.s   Boss_JokerSlowNegativeHorizontalVelocity
                subi.l  #$2000,d0
                bpl.s   Boss_JokerStoreHorizontalVelocity
Boss_JokerClearHorizontalVelocity:                      ; CODE XREF: Boss_JokerSlowHorizontalVelocity+1E   j  ; was: loc_3BC9E
                moveq   #0,d0
Boss_JokerStoreHorizontalVelocity:                      ; CODE XREF: Boss_JokerSlowHorizontalVelocity+E   j  ; was: loc_3BCA0
                move.l  d0,$18(a5)
Boss_JokerSlowHorizontalVelocityReturn:                 ; CODE XREF: Boss_JokerSlowHorizontalVelocity+4   j  ; was: locret_3BCA4
                rts
; ---------------------------------------------------------------------------
Boss_JokerSlowNegativeHorizontalVelocity:               ; CODE XREF: Boss_JokerSlowHorizontalVelocity+6   j  ; was: loc_3BCA6
                addi.l  #$2000,d0
                bpl.s   Boss_JokerClearHorizontalVelocity
                move.l  d0,$18(a5)
                rts
; End of function Boss_JokerSlowHorizontalVelocity
; Interprets one pose-command stream and publishes linked-part angles
Boss_JokerUpdatePose:                                   ; CODE XREF: Boss_JokerUpdatePhaseGatePose+36   p  ; was: sub_3BCB4
                                        ; Boss_JokerUpdateDefeatDescent+2C   p
                clr.w   $3BC(a5)
                tst.w   $C(a5)
                bpl.s   Boss_JokerAdvancePoseInterpolation
Boss_JokerReadNextPoseCommand:                          ; CODE XREF: Boss_JokerUpdatePose+4A   j  ; was: loc_3BCBE
                move.w  $58(a5),d0
                bmi.w   Boss_JokerPublishPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_JokerReadPoseControlWord
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_JokerReadPoseControlWord:                          ; CODE XREF: Boss_JokerUpdatePose+18   j  ; was: loc_3BCE0
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_JokerCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JokerCheckPoseLoopCommand:                         ; CODE XREF: Boss_JokerUpdatePose+34   j  ; was: loc_3BCF0
                cmpi.w  #$FFFF,d3
                bne.s   Boss_JokerStartPoseInterpolation
                clr.w   $58(a5)
                clr.w   $35E(a5)
                bra.s   Boss_JokerReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_JokerStartPoseInterpolation:                       ; CODE XREF: Boss_JokerUpdatePose+40   j  ; was: loc_3BD00
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_JokerPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_JokerCalculatePoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$35E(a5)
                addq.w  #1,$3BC(a5)
                tst.w   $C(a5)
                bmi.s   Boss_JokerPublishPoseAngles
Boss_JokerAdvancePoseInterpolation:                     ; CODE XREF: Boss_JokerUpdatePose+8   j  ; was: loc_3BD36
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #9,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_JokerPublishPoseAngles:                            ; CODE XREF: Boss_JokerUpdatePose+E   j  ; was: loc_3BD46
                                        ; Boss_JokerUpdatePose+80   j
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #1,d6
                move.w  #$1FE,d7
                move.b  (a0),d0
                asl.w   d6,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.w  d0,$116(a5)
                move.b  4(a0),d1
                asl.w   d6,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$176(a5)
                move.w  d1,$1D6(a5)
                move.b  8(a0),d0
                asl.w   d6,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                move.w  d0,$476(a5)
                move.b  $C(a0),d1
                asl.w   d6,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$4D6(a5)
                move.w  d1,$536(a5)
                move.b  $10(a0),d0
                asl.w   d6,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                move.w  d0,$296(a5)
                move.b  $14(a0),d1
                asl.w   d6,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$2F6(a5)
                move.w  d1,$356(a5)
                move.b  $18(a0),d0
                asl.w   d6,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                move.b  $1C(a0),d0
                asl.w   d6,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                move.w  d0,$5F6(a5)
                move.b  $20(a0),d1
                asl.w   d6,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  $24(a0),d0
                asl.w   d6,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                rts
; End of function Boss_JokerUpdatePose
; Calculates the ten channel deltas toward the selected pose target
Boss_JokerCalculatePoseDeltas:                          ; CODE XREF: Boss_JokerUpdatePose+62   p  ; was: sub_3BDF4
                movea.l #Boss_JokerNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #9,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_JokerCalculatePoseDeltas
; Initializes the ten fixed-point pose channels from the source record in A0
Boss_JokerInitializePoseChannels:
                movea.w #(SharedScratchLong0-M68K_RAM),a1  ; was: sub_3BE0A
                moveq   #9,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_JokerInitializePoseChannels
; Spawns Joker's descending directional-shot emitter
Boss_JokerSpawnDescendingShotEmitter:                   ; CODE XREF: Boss_JokerDiveDescentState+42   p  ; was: sub_3BE16
                tst.w   $35C(a5)
                bne.s   Boss_JokerSpawnDescendingShotEmitterReturn
                movea.w #(FortySixthEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward4).l
                bne.s   Boss_JokerSpawnDescendingShotEmitterReturn
                subi.w  #$14,(BossCombatCounter).w
                move.w  #$198,(a0)
                move.w  #$8100,2(a0)
                move.w  #$436A,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                move.b  #$20,$20(a0)                    ; ' '
                move.w  #$50,$24(a0)                    ; 'P'
                move.b  #$80,$21(a0)
                move.l  #$F808F808,$28(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                addi.w  #$26,$14(a0)                    ; '&'
                move.w  #$C0,$48(a0)
                move.w  #4,$4A(a0)
Boss_JokerSpawnDescendingShotEmitterReturn:             ; CODE XREF: Boss_JokerSpawnDescendingShotEmitter+4   j  ; was: locret_3BE82
                                        ; Boss_JokerSpawnDescendingShotEmitter+10   j
                rts
; End of function Boss_JokerSpawnDescendingShotEmitter
; Descends while tracking the player, emits aimed shots, then bursts four ways
Projectile_JokerDescendingShotEmitter:                  ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_3BE84
                tst.w   (StageSpawnCountdown).w
                bmi.s   Projectile_JokerDescendingShotEmitterUpdate
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_JokerDescendingShotEmitterUpdate:            ; CODE XREF: Projectile_JokerDescendingShotEmitter+4   j  ; was: loc_3BE92
                tst.w   $24(a5)
                bpl.s   Projectile_JokerDescendingShotEmitterTrackPlayer
Projectile_JokerDescendingShotEmitterBurst:             ; CODE XREF: Projectile_JokerDescendingShotEmitter+68   j  ; was: loc_3BE98
                jmp     Enemy_SpawnQuadProjectiles
; ---------------------------------------------------------------------------
Projectile_JokerDescendingShotEmitterTrackPlayer:       ; CODE XREF: Projectile_JokerDescendingShotEmitter+12   j  ; was: loc_3BE9E
                cmpi.w  #$148,$14(a5)
                bpl.s   Projectile_JokerDescendingShotEmitterUpdateTimer
                addq.w  #2,$14(a5)
                move.w  (PrimaryEntityXPos).w,$10(a5)
Projectile_JokerDescendingShotEmitterUpdateTimer:       ; CODE XREF: Projectile_JokerDescendingShotEmitter+20   j  ; was: loc_3BEB0
                subq.w  #1,$48(a5)
                bpl.s   Projectile_JokerDescendingShotEmitterUpdatePreShotJitter
                movea.w #(ThirtyEighthEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward4).l
                bne.s   Projectile_JokerDescendingShotEmitterCountEmission
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$8004,d2
                jsr     (Projectile_InitializeAimedDelayedCollisionShot).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$50,d0                         ; 'P'
                move.w  d0,$48(a5)
Projectile_JokerDescendingShotEmitterCountEmission:     ; CODE XREF: Projectile_JokerDescendingShotEmitter+3C   j  ; was: loc_3BEE8
                subq.w  #1,$4A(a5)
                bmi.s   Projectile_JokerDescendingShotEmitterBurst
Projectile_JokerDescendingShotEmitterReturn:            ; CODE XREF: Projectile_JokerDescendingShotEmitter+78   j  ; was: locret_3BEEE
                                        ; Projectile_JokerDescendingShotEmitter+86   j
                rts
; ---------------------------------------------------------------------------
Projectile_JokerDescendingShotEmitterUpdatePreShotJitter:  ; CODE XREF: Projectile_JokerDescendingShotEmitter+30   j  ; was: loc_3BEF0
                move.w  #$F8F8,$A(a5)
                cmpi.w  #$30,$48(a5)                    ; '0'
                bpl.s   Projectile_JokerDescendingShotEmitterReturn
                move.w  #$F7F8,$A(a5)
                btst    #1,(FrameCounter+1).w
                bne.s   Projectile_JokerDescendingShotEmitterReturn
                move.w  #$F9F8,$A(a5)
                rts
; End of function Projectile_JokerDescendingShotEmitter
; ---------------------------------------------------------------------------
Boss_JokerPhaseGatePoses:   dc.w    $1818, 0, $814, $A, $1919, $A, $1818, 0, $814, $A, $1919, $A, $FFFF  ; was: word_3BF14
                                        ; DATA XREF: Boss_JokerUpdatePhaseGatePose   o
Boss_JokerInterruptWaitPoses:   dc.w    $2020, $14, $2020, $1E, $FFFF  ; was: word_3BF2E
                                        ; DATA XREF: Boss_JokerBeginInterruptWaitState+1C   o
Boss_JokerDiveAndJumpPreparationPoses:  dc.w    $1018, $28, $2424, $28, $FFFE  ; was: word_3BF38
                                        ; DATA XREF: Boss_JokerDivePrep+6   o
                                        ; Boss_JokerJumpPreparationState+E   o
Boss_JokerDiveMotionPoses:  dc.w    $E12, $32, $1C1C, $32, $FFFE  ; was: word_3BF42
                                        ; DATA XREF: Boss_JokerDiveMotionState+1C   o
Boss_JokerDiveDescentAndBouncePoses:    dc.w    $E38, $3C, $E0E, $3C, $FFFE  ; was: word_3BF4C
                                        ; DATA XREF: Boss_JokerDiveDescentState+A   o
                                        ; Boss_JokerBounceMotionState+1C   o
Boss_JokerJumpAscentPoses:              dc.w    $F0F, $32, $FFFE  ; DATA XREF: Boss_JokerJumpAscentState+20   o  ; was: word_3BF56
Boss_JokerBodyHeightCompressionPoses:   dc.w    $80C, $3C, $2424, $3C, $FFFE  ; was: word_3BF5C
                                        ; DATA XREF: Boss_JokerJumpAscentState+7A   o
Boss_JokerBodyHeightRecoveryPoses:  dc.w    $6868, $32, $FFFE  ; DATA XREF: Boss_JokerJumpAscentState+A8   o  ; was: word_3BF66
Boss_JokerStretchPoses:             dc.w    $508, $28, $1616, $28, $810, $1E, $2020, $1E, $FFFE  ; was: word_3BF6C
                                        ; DATA XREF: Boss_JokerStretchState+2A   o
Boss_JokerDefeatFallPoses:  dc.w    $E0E, $5A, $E0E, $64, $FFFF  ; was: word_3BF7E
                                        ; DATA XREF: Boss_JokerUpdateDefeatDescent:Boss_JokerAnimateDefeatFall   o
Boss_JokerPoseTable:    dc.w    $40D8, $4028, $64F0, $301C, $10D0, $7000, $C060, $78FA  ; was: word_3BF88
                                        ; DATA XREF: Boss_JokerUpdatePose+5A   o
                dc.w    $3CF0, $68A8, $40F0, $4010, $9098, $58F0, $68A8, $80B0
                dc.w    $50, $78B4, $5808, $4CA8, $9020, $F0E0, $A890, $48D8
                dc.w    $70B8, $2000, $6000, $30F8, $2050, $8E0, $9010, $F0F0
                dc.w    $70E0, $5810, $20A8, $40F0, $4010, $30F8, $5050, $8B0
                dc.w    $6810, $18F0, $8010, $2000, $F0E0, $A020, $2020, $9090
                dc.w    $58D0, $20A0, $60E0, $E0E0, $B0E0, $60F0, $7098

; Main Flying-Neo boss handler with state dispatch
