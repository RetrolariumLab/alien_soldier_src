; Main Sunset Sting boss handler
; REVIEWED VIS-003: pinned TAS frames 32124 and 32200 show type $1EC; see docs/unknowns.md
Boss_SunsetStingMain:                                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_42A10
                lea     (SunsetStingSharedState).w,a4
                lea     (SecondaryEntityType).w,a3
                bsr.s   Boss_SunsetStingDispatcher
                bsr.w   Boss_SunsetStingUpdateWaveScreen
                move.w  4(a5),d0
                andi.w  #$FF,d0
                cmpi.w  #$12,d0
                bcc.s   Boss_SunsetStingMainReturn
                jsr     (Gfx_ProcessDefaultColorFade).l
                tst.w   (BossCombatCounter).w
                bne.s   Boss_SunsetStingMainCheckDefeatTrigger
                move.w  4(a5),d0
                andi.w  #$7FFF,d0
                cmpi.w  #$E,d0
                bcc.s   Boss_SunsetStingMainCheckDefeatTrigger
                addi.b  #$20,$54(a5)                    ; ' '
                bne.s   Boss_SunsetStingMainCheckDefeatTrigger
                move.w  #$E,4(a5)
Boss_SunsetStingMainCheckDefeatTrigger:                 ; CODE XREF: Boss_SunsetStingMain+26   j  ; was: loc_42A54
                                        ; Boss_SunsetStingMain+34   j
                tst.w   (BossHealth).w
                bne.s   Boss_SunsetStingMainCycleTiles
                bset    #0,(StageTimerPauseFlag).w
                bset    #7,(a4)
                move.w  #$12,4(a5)
Boss_SunsetStingMainCycleTiles:                         ; CODE XREF: Boss_SunsetStingMain+48   j  ; was: loc_42A6A
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_SunsetStingMainReturn
                move.b  $48(a5),d0
                andi.w  #$F,d0
                movea.l Boss_SunsetStingTileLoadCommands(pc,d0.w),a0
                jsr     (Tilemap_QueueIndexedRows).l
                addq.b  #4,$48(a5)
Boss_SunsetStingMainReturn:                             ; CODE XREF: Boss_SunsetStingMain+1A   j  ; was: locret_42A8A
                                        ; Boss_SunsetStingMain+62   j
                rts
; End of function Boss_SunsetStingMain
; State dispatcher for boss
Boss_SunsetStingDispatcher:                             ; CODE XREF: Boss_SunsetStingMain+8   p  ; was: sub_42A8C
                                        ; Boss_SunsetStingBattleActive+8C   j
                move.w  4(a5),d0
                andi.w  #$FF,d0
                lea     Boss_SunsetStingStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SunsetStingDispatcher
; ---------------------------------------------------------------------------
Boss_SunsetStingStates: dc.w    Boss_SunsetStingInit-*  ; DATA XREF: Boss_SunsetStingDispatcher+8   o  ; was: off_42A9C
                dc.w    Boss_SunsetStingIntro-*
                dc.w    Boss_SunsetStingBattleActive-*
                dc.w    Boss_SunsetStingBeginCoreRepositionState-*
                dc.w    Boss_SunsetStingCoreRepositionState-*
                dc.w    Boss_SunsetStingRotateSegmentsPositiveState-*
                dc.w    Boss_SunsetStingRotateSegmentsNegativeState-*
                dc.w    Boss_SunsetStingBrakeSegmentRotationState-*
                dc.w    Boss_SunsetStingRefillCounterAndOscillateState-*
                dc.w    Boss_SunsetStingBeginDefeatState-*
                dc.w    Boss_SunsetStingDefeatWobbleState-*
                dc.w    Boss_SunsetStingFinalDefeatState-*
                dc.w    Boss_SunsetStingDefeatFadeOutState-*
Boss_SunsetStingTileLoadCommands:
                dc.l    Boss_SunsetStingTileLoadCommandA  ; DATA XREF: Boss_SunsetStingMain+6C   r  ; was: off_42AB6
                dc.l    Boss_SunsetStingTileLoadCommandB
                dc.l    Boss_SunsetStingTileLoadCommandC
                dc.l    Boss_SunsetStingTileLoadCommandB
Boss_SunsetStingTileLoadCommandA:
                dc.w    $625C, $2000, 0, $6700          ; was: word_42AC6
Boss_SunsetStingTileLoadCommandB:
                dc.w    $625C, $2000, 0, $6800          ; was: word_42ACE
                                        ; DATA XREF: ROM:00042ABA   o
                                        ; ROM:00042AC2   o
Boss_SunsetStingTileLoadCommandC:
                dc.w    $625C, $2000, 0, $6B00          ; was: word_42AD6
                                        ; DATA XREF: ROM:00042ABE   o

; Initializes Sunset Sting boss with 16 segments
Boss_SunsetStingInit:                                   ; DATA XREF: ROM:Boss_SunsetStingStates   o  ; was: sub_42ADE
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_SunsetStingReturn
                move.w  #$1EC,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                if      BuildProfileJP
                move.b  #1,(SoundFadeOutDelay).w
                endif
                move.w  #$1E0,$10(a5)
                move.w  #$D8,$14(a5)
                move.w  #$8D00,2(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                move.b  #$84,$23(a5)
                move.w  #$14,$24(a5)
                move.w  #$95,$26(a5)
                move.l  #$F010F010,$28(a5)
                move.l  #$F20EF20E,$2C(a5)
                move.b  #$40,(PlayerOAMBucketOffset).w  ; '@'
                lea     $60(a5),a0
                move.w  #$20C,(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.w  #$95,$26(a0)
                move.w  #$6300,$E(a0)
                moveq   #0,d0
                lea     Boss_SunsetStingPrimarySegmentTemplate(pc),a1
                moveq   #0,d2
                lea     $60(a0),a0
                bra.s   Boss_SunsetStingInitSegmentGroup
; ---------------------------------------------------------------------------
Boss_SunsetStingInitSecondarySegmentGroup:              ; CODE XREF: Boss_SunsetStingInit+C0   j  ; was: loc_42B60
                moveq   #$40,d0                         ; '@'
                lea     Boss_SunsetStingSecondarySegmentTemplate(pc),a1
Boss_SunsetStingInitSegmentGroup:                       ; CODE XREF: Boss_SunsetStingInit+80   j  ; was: loc_42B66
                moveq   #7,d7
Boss_SunsetStingInitSegmentLoop:                        ; CODE XREF: Boss_SunsetStingInit+B6   j  ; was: loc_42B68
                move.w  #$6300,$E(a0)
                move.w  (a1),(a0)
                move.w  2(a1),$26(a0)
                move.l  4(a1),$28(a0)
                move.l  8(a1),$2C(a0)
                move.w  d0,6(a0)
                move.w  d2,$46(a0)
                addi.w  #$80,d0
                addq.w  #1,d2
                lea     $60(a0),a0
                dbf     d7,Boss_SunsetStingInitSegmentLoop
                cmpa.l  #Boss_SunsetStingSecondarySegmentTemplate,a1
                bne.s   Boss_SunsetStingInitSecondarySegmentGroup
                move.w  #8,4(a4)
                move.w  #2,(ScrollPlaneBufferOffset).w
                lea     Boss_SunsetStingInitialTileLoadCommand(pc),a0
                jsr     (Tilemap_QueueIndexedRows).l
                bra.w   Boss_SunsetStingNextState
; End of function Boss_SunsetStingInit
; ---------------------------------------------------------------------------
Boss_SunsetStingInitialTileLoadCommand:
                dc.w    $6058, $2000, $105, $6C6F, $7073, $6566, $696A, $6D6E, $7172  ; was: word_42BBA
                                        ; DATA XREF: Boss_SunsetStingInit+CE   o
Boss_SunsetStingPrimarySegmentTemplate:
                dc.w    $1F0, $52, $F40C, $F40C, $FC04, $FC04  ; was: word_42BCC
                                        ; DATA XREF: Boss_SunsetStingInit+76   o
Boss_SunsetStingSecondarySegmentTemplate:
                dc.w    $1F4, $25, 0, 0, $FE02, $F808   ; was: word_42BD8
                                        ; DATA XREF: Boss_SunsetStingInit+84   o
                                        ; Boss_SunsetStingInit+BA   o

; Boss intro sequence
Boss_SunsetStingIntro:                                  ; DATA XREF: ROM:00042A9E   o  ; was: sub_42BE4
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingIntroUpdate
                move.w  #$780,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  d0,$10(a3)
                move.w  #$10,$14(a5)
                move.w  #$90,$14(a3)
                clr.b   (PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                move.b  #0,(VDPReg11Shadow+1).w
                move.w  #$34,(RasterEffectIndex).w      ; '4'
                clr.w   (RasterEffectInitState).w
                bclr    #0,(a4)
                move.l  #$FFFFF000,$58(a5)
                move.w  #1,$1C(a5)
Boss_SunsetStingIntroUpdate:                            ; CODE XREF: Boss_SunsetStingIntro+6   j  ; was: loc_42C34
                btst    #6,4(a5)
                bne.s   Boss_SunsetStingWaitForBattleBanner
                cmpi.w  #$140,$14(a3)
                beq.s   Boss_SunsetStingIntroCheckEntryComplete
                addq.w  #2,$14(a3)
                cmpi.w  #$140,$14(a3)
                bne.s   Boss_SunsetStingIntroCheckEntryComplete
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  #2,$1C(a5)
Boss_SunsetStingIntroCheckEntryComplete:                ; CODE XREF: Boss_SunsetStingIntro+5E   j  ; was: loc_42C62
                                        ; Boss_SunsetStingIntro+6A   j
                cmpi.w  #$C0,$14(a5)
                bcs.w   Boss_SunsetStingReturn
                bset    #6,4(a5)
                moveq   #3,d0
; End of function Boss_SunsetStingIntro
; Starts the shared battle-entry banner and input mode
Boss_SunsetStingStartBattleBanner:                      ; was: sub_42C74
                jsr     (BossMessage_Start).l
                move.b  #$8A,d0
                jsr     (Sound_QueueBGMOrStop).l
                rts
; End of function Boss_SunsetStingStartBattleBanner
; Oscillates vertically while the battle-entry banner remains active
Boss_SunsetStingWaitForBattleBanner:                    ; CODE XREF: Boss_SunsetStingIntro+56   j  ; was: sub_42C86
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                moveq   #1,d7
                swap    d7
                tst.w   $58(a5)
                bpl.s   Boss_SunsetStingIntroSelectOscillationLimit
                neg.l   d7
Boss_SunsetStingIntroSelectOscillationLimit:            ; CODE XREF: Boss_SunsetStingWaitForBattleBanner+10   j  ; was: loc_42C9A
                cmp.l   $1C(a5),d7
                bne.s   Boss_SunsetStingIntroWaitForBanner
                neg.l   $58(a5)
Boss_SunsetStingIntroWaitForBanner:                     ; CODE XREF: Boss_SunsetStingWaitForBattleBanner+18   j  ; was: loc_42CA4
                tst.w   (MessageSequenceState).w
                bne.w   Boss_SunsetStingReturn
                clr.b   (BossColorEffectFlags).w
                move.w  #$620,(CameraXLowerBound).w
                move.w  #$6A0,(CameraXUpperBound).w
                bra.w   Boss_SunsetStingNextState
; End of function Boss_SunsetStingWaitForBattleBanner
; Active battle state
Boss_SunsetStingBattleActive:                           ; DATA XREF: ROM:00042AA0   o  ; was: sub_42CC0
                bsr.w   Physics_ClearVelocity
                btst    #0,(a4)
                bne.s   Boss_SunsetStingBattleApproachPlayer
                clr.l   $4A(a5)
                moveq   #1,d7
                move.w  $14(a3),d0
                subi.w  #$71,d0                         ; 'q'
                cmp.w   $14(a5),d0
                beq.s   Boss_SunsetStingBattleChooseState
                bpl.s   Boss_SunsetStingBattleMoveVertically
                neg.w   d7
Boss_SunsetStingBattleMoveVertically:                   ; CODE XREF: Boss_SunsetStingBattleActive+1E   j  ; was: loc_42CE2
                add.w   d7,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingBattleApproachPlayer:                   ; CODE XREF: Boss_SunsetStingBattleActive+8   j  ; was: loc_42CE8
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingBattleBrakeRotation
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_SunsetStingBattleMeasureHorizontalDistance
                neg.w   d0
Boss_SunsetStingBattleMeasureHorizontalDistance:        ; CODE XREF: Boss_SunsetStingBattleActive+38   j  ; was: loc_42CFC
                cmpi.w  #$80,d0
                bcc.s   Boss_SunsetStingBattleChooseState
                move.l  $58(a5),d0
                asr.l   #5,d0
                move.w  d0,$4A(a5)
                move.w  #$20,$4C(a5)                    ; ' '
Boss_SunsetStingBattleBrakeRotation:                    ; CODE XREF: Boss_SunsetStingBattleActive+2E   j  ; was: loc_42D12
                move.w  $4A(a5),d0
                ext.l   d0
                sub.l   d0,$58(a5)
                subq.w  #1,$4C(a5)
                bne.w   Boss_SunsetStingMainReturn
                move.w  #6,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingBattleChooseState:                      ; CODE XREF: Boss_SunsetStingBattleActive+1C   j  ; was: loc_42D2C
                                        ; Boss_SunsetStingBattleActive+40   j
                tst.w   $4C(a5)
                beq.s   Boss_SunsetStingBattleSelectAttack
                move.w  $4C(a5),d0
                bpl.s   Boss_SunsetStingBattleNormalizeRotationSpeed
                neg.w   d0
Boss_SunsetStingBattleNormalizeRotationSpeed:           ; CODE XREF: Boss_SunsetStingBattleActive+76   j  ; was: loc_42D3A
                cmpi.w  #$20,d0                         ; ' '
                bne.s   Boss_SunsetStingBattleResumeMovement
                move.w  #$A,4(a5)
                move.w  #$200,$56(a5)
                bra.w   Boss_SunsetStingDispatcher
; ---------------------------------------------------------------------------
Boss_SunsetStingBattleResumeMovement:                   ; CODE XREF: Boss_SunsetStingBattleActive+7E   j  ; was: loc_42D50
                clr.l   $4A(a5)
                move.w  #6,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingBattleSelectAttack:                     ; CODE XREF: Boss_SunsetStingBattleActive+70   j  ; was: loc_42D5C
                move.w  #$FFFF,2(a4)
                subi.w  #$50,(BossCombatCounter).w      ; 'P'
                moveq   #$A,d7
                jsr     (RandomNumber).l
                andi.w  #7,d0
                bne.s   Boss_SunsetStingBattleStoreAttackState
                addq.w  #2,d7
Boss_SunsetStingBattleStoreAttackState:                 ; CODE XREF: Boss_SunsetStingBattleActive+B4   j  ; was: loc_42D78
                move.w  d7,4(a5)
                move.w  #$200,$56(a5)
                clr.l   $4A(a5)
                rts
; End of function Boss_SunsetStingBattleActive
; Begins the shared core/controller vertical reposition cycle
Boss_SunsetStingBeginCoreRepositionState:               ; DATA XREF: ROM:00042AA2   o  ; was: sub_42D88
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingBeginCoreRepositionDelay
                clr.b   (PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                move.b  #0,(VDPReg11Shadow+1).w
                move.w  #$34,(RasterEffectIndex).w      ; '4'
                clr.w   (RasterEffectInitState).w
                bclr    #0,(a4)
                move.w  #$14,$4A(a5)
Boss_SunsetStingBeginCoreRepositionDelay:               ; CODE XREF: Boss_SunsetStingBeginCoreRepositionState+6   j  ; was: loc_42DB4
                addq.w  #2,$14(a5)
                subq.w  #1,$4A(a5)
                bne.w   Boss_SunsetStingReturn
                move.l  #$FFFBC000,$1C(a5)
                move.l  #$1000,$4A(a5)
                addi.w  #$30,(BossCombatCounter).w      ; '0'
                bra.w   Boss_SunsetStingNextState
; End of function Boss_SunsetStingBeginCoreRepositionState
; Repositions the visible core and its controller before resuming battle
Boss_SunsetStingCoreRepositionState:                    ; DATA XREF: ROM:00042AA4   o  ; was: sub_42DDA
                btst    #6,4(a5)
                bne.w   Boss_SunsetStingCoreRepositionUpdateController
                tst.l   $4A(a3)
                beq.s   Boss_SunsetStingCoreRepositionLaunchCore
                move.l  $4A(a3),d0
                add.l   d0,$1C(a3)
                bmi.s   Boss_SunsetStingCoreRepositionTrackX
                move.w  #$102,$26(a3)
Boss_SunsetStingCoreRepositionTrackX:                   ; CODE XREF: Boss_SunsetStingCoreRepositionState+18   j  ; was: loc_42DFA
                move.w  $10(a3),$10(a5)
                cmpi.w  #$140,$14(a3)
                bcs.w   Boss_SunsetStingCoreRepositionUpdateController
                move.w  #$95,$26(a3)
                move.w  #$140,$14(a3)
                move.w  #8,(PlaneBShakeLevel).w
                clr.l   $18(a3)
                clr.l   $1C(a3)
                clr.l   $4A(a3)
                subi.w  #$50,(BossCombatCounter).w      ; 'P'
                bset    #6,4(a5)
                bra.s   Boss_SunsetStingCoreRepositionUpdateController
; ---------------------------------------------------------------------------
Boss_SunsetStingCoreRepositionLaunchCore:               ; CODE XREF: Boss_SunsetStingCoreRepositionState+E   j  ; was: loc_42E36
                move.w  $14(a3),d0
                sub.w   $14(a5),d0
                cmpi.w  #$A0,d0
                bcs.s   Boss_SunsetStingCoreRepositionUpdateController
                move.l  #$FFFA0000,$1C(a3)
                move.l  #$2000,$4A(a3)
                move.w  $10(a5),d0
                move.w  d0,d1
                add.w   (PrimaryCameraXPosition).w,d0
                move.l  #$FFFF0000,d7
                subi.w  #$780,d0
                bpl.s   Boss_SunsetStingCoreRepositionSelectXVelocity
                neg.w   d0
                neg.l   d7
Boss_SunsetStingCoreRepositionSelectXVelocity:          ; CODE XREF: Boss_SunsetStingCoreRepositionState+8E   j  ; was: loc_42E6E
                subi.w  #$80,d0
                bcc.s   Boss_SunsetStingCoreRepositionStoreXVelocity
                move.l  #$10000,d7
                cmp.w   (PlayerXPosition).w,d1
                bpl.s   Boss_SunsetStingCoreRepositionStoreXVelocity
                neg.l   d7
Boss_SunsetStingCoreRepositionStoreXVelocity:           ; CODE XREF: Boss_SunsetStingCoreRepositionState+98   j  ; was: loc_42E82
                                        ; Boss_SunsetStingCoreRepositionState+A4   j
                move.l  d7,$18(a3)
Boss_SunsetStingCoreRepositionUpdateController:         ; CODE XREF: Boss_SunsetStingCoreRepositionState+6   j  ; was: loc_42E86
                                        ; Boss_SunsetStingCoreRepositionState+2C   j
                btst    #7,4(a5)
                bne.s   Boss_SunsetStingCoreRepositionAlignController
                move.l  $4A(a5),d0
                add.l   d0,$1C(a5)
                cmpi.l  #$44000,$1C(a5)
                bne.w   Boss_SunsetStingReturn
                clr.l   $1C(a5)
                bset    #7,4(a5)
Boss_SunsetStingCoreRepositionAlignController:          ; CODE XREF: Boss_SunsetStingCoreRepositionState+B2   j  ; was: loc_42EAC
                move.w  $14(a3),d0
                subi.w  #$71,d0                         ; 'q'
                cmp.w   $14(a5),d0
                beq.s   Boss_SunsetStingCoreRepositionFinish
                subq.w  #1,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingCoreRepositionFinish:                   ; CODE XREF: Boss_SunsetStingCoreRepositionState+DE   j  ; was: loc_42EC0
                move.w  #4,4(a5)
                rts
; End of function Boss_SunsetStingCoreRepositionState
; Rotates the segment ring in the positive direction and releases segments
Boss_SunsetStingRotateSegmentsPositiveState:            ; DATA XREF: ROM:00042AA6   o  ; was: sub_42EC8
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingRotateSegmentsPositiveUpdate
                move.b  #4,(PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                andi.b  #$EF,(VDPReg0Shadow+1).w
                move.b  #3,(VDPReg11Shadow+1).w
                bset    #0,(a4)
                jsr     (RandomNumber).l
                andi.w  #$3F,d0                         ; '?'
                move.b  d0,$49(a5)
                tst.w   $4A(a5)
                bne.s   Boss_SunsetStingRotateSegmentsPositiveUpdate
                move.w  #$FD00,$4A(a5)
                move.w  #$20,$4C(a5)                    ; ' '
Boss_SunsetStingRotateSegmentsPositiveUpdate:           ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState+6   j  ; was: loc_42F0C
                                        ; Boss_SunsetStingRotateSegmentsPositiveState+36   j
                subq.w  #1,$56(a5)
                bne.s   Boss_SunsetStingRotateSegmentsPositiveMotion
                move.w  #4,4(a5)
Boss_SunsetStingRotateSegmentsPositiveMotion:           ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState+48   j  ; was: loc_42F18
                bsr.s   Boss_SunsetStingMoveCoreTowardPlayer
                move.w  #$300,d7
                bsr.s   Boss_SunsetStingUpdateSegmentRotation
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Boss_SunsetStingRotateSegmentsPositiveSelect
                cmpi.w  #8,4(a4)
                beq.s   Boss_SunsetStingRotateSegmentsPositiveSelect
                addq.w  #1,4(a4)
Boss_SunsetStingRotateSegmentsPositiveSelect:           ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState+60   j  ; was: loc_42F36
                                        ; Boss_SunsetStingRotateSegmentsPositiveState+68   j
                clr.w   2(a4)
                subq.b  #1,$49(a5)
                bne.w   Boss_SunsetStingReturn
                jsr     (RandomNumber).l
                andi.b  #$3F,d0                         ; '?'
                tst.w   (DifficultyMode).w
                beq.s   Boss_SunsetStingRotateSegmentsPositiveArm
                lsr.b   #1,d0
Boss_SunsetStingRotateSegmentsPositiveArm:              ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState+88   j  ; was: loc_42F54
                move.b  d0,$49(a5)
                swap    d0
                andi.w  #$F,d0
                bset    #3,d0
                moveq   #0,d1
                bset    d0,d1
                move.w  d1,2(a4)
                rts
; End of function Boss_SunsetStingRotateSegmentsPositiveState
; Moves the visible core horizontally toward the player
Boss_SunsetStingMoveCoreTowardPlayer:                   ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState:Boss_SunsetStingRotateSegmentsPositiveMotion   p  ; was: sub_42F6C
                                        ; sub_42FA6:loc_42FF6   p
                moveq   #1,d7
                ror.w   #3,d7
                move.w  $10(a5),d0
                cmp.w   (PlayerXPosition).w,d0
                bpl.s   Boss_SunsetStingMoveCoreTowardPlayerApply
                neg.l   d7
Boss_SunsetStingMoveCoreTowardPlayerApply:              ; CODE XREF: Boss_SunsetStingMoveCoreTowardPlayer+C   j  ; was: loc_42F7C
                sub.l   d7,$10(a3)
                rts
; End of function Boss_SunsetStingMoveCoreTowardPlayer
; Updates the shared segment angle and reverses its angular acceleration at a limit
Boss_SunsetStingUpdateSegmentRotation:                  ; CODE XREF: Boss_SunsetStingRotateSegmentsPositiveState+56   p  ; was: sub_42F82
                                        ; Boss_SunsetStingRotateSegmentsNegativeState+58   p
                move.w  $4C(a5),d0
                add.w   d0,$4A(a5)
                move.w  $4A(a5),d0
                ext.l   d0
                add.l   d0,$58(a5)
                tst.w   $4C(a5)
                bpl.s   Boss_SunsetStingUpdateSegmentRotationCheckLimit
                neg.w   d0
Boss_SunsetStingUpdateSegmentRotationCheckLimit:        ; CODE XREF: Boss_SunsetStingUpdateSegmentRotation+16   j  ; was: loc_42F9C
                cmp.w   d7,d0
                bne.s   Boss_SunsetStingUpdateSegmentRotationReturn
                neg.w   $4C(a5)
Boss_SunsetStingUpdateSegmentRotationReturn:            ; CODE XREF: Boss_SunsetStingUpdateSegmentRotation+1C   j  ; was: locret_42FA4
                rts
; End of function Boss_SunsetStingUpdateSegmentRotation
; Rotates the segment ring in the negative direction and releases segments
Boss_SunsetStingRotateSegmentsNegativeState:            ; DATA XREF: ROM:00042AA8   o  ; was: sub_42FA6
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingRotateSegmentsNegativeUpdate
                move.b  #4,(PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                andi.b  #$EF,(VDPReg0Shadow+1).w
                move.b  #3,(VDPReg11Shadow+1).w
                bset    #0,(a4)
                jsr     (RandomNumber).l
                andi.w  #$3F,d0                         ; '?'
                move.b  d0,$49(a5)
                tst.w   $4A(a5)
                bne.s   Boss_SunsetStingRotateSegmentsNegativeUpdate
                move.w  #$F000,$4A(a5)
                move.w  #$200,$4C(a5)
Boss_SunsetStingRotateSegmentsNegativeUpdate:           ; CODE XREF: Boss_SunsetStingRotateSegmentsNegativeState+6   j  ; was: loc_42FEA
                                        ; Boss_SunsetStingRotateSegmentsNegativeState+36   j
                subq.w  #1,$56(a5)
                bne.s   Boss_SunsetStingRotateSegmentsNegativeMotion
                move.w  #4,4(a5)
Boss_SunsetStingRotateSegmentsNegativeMotion:           ; CODE XREF: Boss_SunsetStingRotateSegmentsNegativeState+48   j  ; was: loc_42FF6
                bsr.w   Boss_SunsetStingMoveCoreTowardPlayer
                move.w  #$1000,d7
                bsr.s   Boss_SunsetStingUpdateSegmentRotation
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_SunsetStingRotateSegmentsNegativeSelect
                cmpi.w  #$FFF8,4(a4)
                beq.s   Boss_SunsetStingRotateSegmentsNegativeSelect
                subq.w  #1,4(a4)
Boss_SunsetStingRotateSegmentsNegativeSelect:           ; CODE XREF: Boss_SunsetStingRotateSegmentsNegativeState+62   j  ; was: loc_43016
                                        ; Boss_SunsetStingRotateSegmentsNegativeState+6A   j
                clr.w   2(a4)
                subq.b  #1,$49(a5)
                bne.w   Boss_SunsetStingReturn
                jsr     (RandomNumber).l
                andi.b  #$7F,d0
                tst.w   (DifficultyMode).w
                beq.s   Boss_SunsetStingRotateSegmentsNegativeArm
                lsr.b   #1,d0
Boss_SunsetStingRotateSegmentsNegativeArm:              ; CODE XREF: Boss_SunsetStingRotateSegmentsNegativeState+8A   j  ; was: loc_43034
                move.b  d0,$49(a5)
                swap    d0
                andi.w  #7,d0
                moveq   #0,d1
                bset    d0,d1
                move.w  d1,2(a4)
                rts
; End of function Boss_SunsetStingRotateSegmentsNegativeState
; Brakes segment rotation and realigns the controller with the visible core
Boss_SunsetStingBrakeSegmentRotationState:              ; DATA XREF: ROM:00042AAA   o  ; was: sub_43048
                bsr.w   Physics_ClearVelocity
                btst    #0,(a4)
                bne.s   Boss_SunsetStingBrakeSegmentRotation
                clr.l   $4A(a5)
                moveq   #1,d7
                move.w  $14(a3),d0
                subi.w  #$71,d0                         ; 'q'
                cmp.w   $14(a5),d0
                beq.w   Boss_SunsetStingIncrementState
                bpl.s   Boss_SunsetStingAlignControllerVertically
                neg.w   d7
Boss_SunsetStingAlignControllerVertically:              ; CODE XREF: Boss_SunsetStingBrakeSegmentRotationState+20   j  ; was: loc_4306C
                add.w   d7,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingBrakeSegmentRotation:                   ; CODE XREF: Boss_SunsetStingBrakeSegmentRotationState+8   j  ; was: loc_43072
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingBrakeSegmentRotationUpdate
                move.l  $58(a5),d0
                asr.l   #5,d0
                move.w  d0,$4A(a5)
                move.w  #$20,$4C(a5)                    ; ' '
Boss_SunsetStingBrakeSegmentRotationUpdate:             ; CODE XREF: Boss_SunsetStingBrakeSegmentRotationState+30   j  ; was: loc_4308A
                move.w  $4A(a5),d0
                ext.l   d0
                sub.l   d0,$58(a5)
                subq.w  #1,$4C(a5)
                beq.w   Boss_SunsetStingNextState
                rts
; End of function Boss_SunsetStingBrakeSegmentRotationState
; Oscillates the controller while refilling the boss counter to its HUD maximum
; REVIEWED VIS-003: state $10 behaviour is static; its appearance was not captured
Boss_SunsetStingRefillCounterAndOscillateState:         ; DATA XREF: ROM:00042AAC   o  ; was: sub_4309E
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingCounterRefillOscillationUpdate
                clr.b   (PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                move.b  #0,(VDPReg11Shadow+1).w
                move.w  #$34,(RasterEffectIndex).w      ; '4'
                clr.w   (RasterEffectInitState).w
                bclr    #0,(a4)
                move.w  #$14,$4A(a5)
                move.l  #$FFFFF000,$58(a5)
                move.w  #1,$1C(a5)
Boss_SunsetStingCounterRefillOscillationUpdate:         ; CODE XREF: Boss_SunsetStingRefillCounterAndOscillateState+6   j  ; was: loc_430D8
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                moveq   #1,d7
                swap    d7
                tst.w   $58(a5)
                bpl.s   Boss_SunsetStingSelectOscillationLimit
                neg.l   d7
Boss_SunsetStingSelectOscillationLimit:                 ; CODE XREF: Boss_SunsetStingRefillCounterAndOscillateState+4A   j  ; was: loc_430EC
                cmp.l   $1C(a5),d7
                bne.s   Boss_SunsetStingCheckCounterMaximum
                neg.l   $58(a5)
Boss_SunsetStingCheckCounterMaximum:                    ; CODE XREF: Boss_SunsetStingRefillCounterAndOscillateState+52   j  ; was: loc_430F6
                addq.w  #2,(BossCombatCounter).w
                btst    #0,(BossCounterMaxFlag).w
                beq.w   Boss_SunsetStingReturn
                move.w  #4,4(a5)
                rts
; End of function Boss_SunsetStingRefillCounterAndOscillateState
; Starts the defeat sequence and moves both core objects into alignment
Boss_SunsetStingBeginDefeatState:                       ; DATA XREF: ROM:00042AAE   o  ; was: sub_4310C
                move.b  #1,(SoundFadeOutDelay).w
                clr.b   $21(a5)
                clr.b   $23(a5)
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bset    #7,4(a5)
                bne.s   Boss_SunsetStingBeginDefeatMoveIntoPosition
                clr.b   (PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                move.b  #0,(VDPReg11Shadow+1).w
                move.w  #$34,(RasterEffectIndex).w      ; '4'
                clr.w   (RasterEffectInitState).w
                bclr    #0,(a4)
                move.w  $10(a3),$10(a5)
                bsr.w   Physics_ClearVelocity
                move.l  d0,$18(a3)
                move.l  d0,$1C(a3)
                move.l  d0,$4A(a3)
Boss_SunsetStingBeginDefeatMoveIntoPosition:            ; CODE XREF: Boss_SunsetStingBeginDefeatState+1A   j  ; was: loc_4315C
                moveq   #0,d1
                move.w  $14(a3),d0
                cmpi.w  #$140,d0
                bcc.s   Boss_SunsetStingBeginDefeatAlignController
                addq.w  #2,$14(a3)
                addq.w  #1,d1
Boss_SunsetStingBeginDefeatAlignController:             ; CODE XREF: Boss_SunsetStingBeginDefeatState+5A   j  ; was: loc_4316E
                moveq   #1,d7
                subi.w  #$71,d0                         ; 'q'
                cmp.w   $14(a5),d0
                beq.s   Boss_SunsetStingBeginDefeatCheckAlignment
                bpl.s   Boss_SunsetStingBeginDefeatMoveController
                neg.w   d7
Boss_SunsetStingBeginDefeatMoveController:              ; CODE XREF: Boss_SunsetStingBeginDefeatState+6E   j  ; was: loc_4317E
                add.w   d7,$14(a5)
                addq.w  #1,d1
Boss_SunsetStingBeginDefeatCheckAlignment:              ; CODE XREF: Boss_SunsetStingBeginDefeatState+6C   j  ; was: loc_43184
                tst.w   d1
                bne.w   Boss_SunsetStingReturn
                move.w  #$100,$4A(a5)
                clr.l   $4C(a5)
                move.w  #$FFF8,$1C(a5)
                addi.w  #$20,$14(a5)                    ; ' '
                bra.w   Boss_SunsetStingNextState
; End of function Boss_SunsetStingBeginDefeatState
; Wobble effect during defeat
Boss_SunsetStingDefeatWobbleState:                      ; DATA XREF: ROM:00042AB0   o  ; was: sub_431A4
                addi.b  #$40,$4C(a5)                    ; '@'
                bne.s   Boss_SunsetStingDefeatWobbleUpdate
                neg.l   $1C(a5)
Boss_SunsetStingDefeatWobbleUpdate:                     ; CODE XREF: Boss_SunsetStingDefeatWobbleState+6   j  ; was: loc_431B0
                bsr.s   Boss_SunsetStingSpawnDebrisRain
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$4A(a5)
                beq.w   Boss_SunsetStingNextState
                rts
; End of function Boss_SunsetStingDefeatWobbleState
; Spawns debris rain projectiles
Boss_SunsetStingSpawnDebrisRain:                        ; CODE XREF: Boss_SunsetStingDefeatWobbleState:Boss_SunsetStingDefeatWobbleUpdate   p  ; was: sub_431C2
                                        ; sub_43226:loc_43232   p
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_SunsetStingReturn
                jsr     (Projectile_InitType88).l
                move.w  (RandomNumberState).w,d0
                move.w  (RandomNumberState+2).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d0                         ; ' '
                subi.w  #$20,d1                         ; ' '
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                move.b  #$30,$20(a0)                    ; '0'
                bset    #7,$E(a0)
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Boss_SunsetStingReturn
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Boss_SunsetStingSpawnDebrisRain
; Final defeat sequence
Boss_SunsetStingFinalDefeatState:                       ; DATA XREF: ROM:00042AB2   o  ; was: sub_43226
                addi.b  #$40,$4C(a5)                    ; '@'
                bne.s   Boss_SunsetStingFinalDefeatUpdate
                neg.l   $1C(a5)
Boss_SunsetStingFinalDefeatUpdate:                      ; CODE XREF: Boss_SunsetStingFinalDefeatState+6   j  ; was: loc_43232
                bsr.s   Boss_SunsetStingSpawnDebrisRain
                bsr.s   Boss_SunsetStingApplyDefeatFade
                cmpi.w  #$1C,6(a5)
                bcs.s   Boss_SunsetStingFinalDefeatAdvanceFade
                beq.s   Boss_SunsetStingFinalDefeatDisableCollision
                addq.b  #8,$4A(a5)
                bne.w   Boss_SunsetStingReturn
                move.w  #$1EC,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                jsr     (TransitionEffect_SpawnAtOwner).l
                clr.w   (ScrollPlaneBufferOffset).w
                clr.l   $1C(a5)
                addi.w  #$38,$14(a0)                    ; '8'
                andi.w  #$FFFE,6(a5)
                move.w  #$FF00,$4A(a5)
                bra.w   Boss_SunsetStingNextState
; ---------------------------------------------------------------------------
Boss_SunsetStingFinalDefeatDisableCollision:            ; CODE XREF: Boss_SunsetStingFinalDefeatState+18   j  ; was: loc_43278
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #4,(PlaneAScrollModeFlags).w
                clr.w   2(a5)
                move.b  #$FF,(a4)
Boss_SunsetStingFinalDefeatAdvanceFade:                 ; CODE XREF: Boss_SunsetStingFinalDefeatState+16   j  ; was: loc_4328E
                addq.w  #1,6(a5)
                rts
; End of function Boss_SunsetStingFinalDefeatState
; Fade out after defeat
Boss_SunsetStingDefeatFadeOutState:                     ; DATA XREF: ROM:00042AB4   o  ; was: sub_43294
                tst.w   6(a5)
                beq.s   Boss_SunsetStingDefeatFadeOutApply
                subq.w  #2,6(a5)
Boss_SunsetStingDefeatFadeOutApply:                     ; CODE XREF: Boss_SunsetStingDefeatFadeOutState+4   j  ; was: loc_4329E
                bsr.s   Boss_SunsetStingApplyDefeatFade
                addq.w  #2,$4A(a5)
                bne.w   Boss_SunsetStingReturn
                bset    #4,2(a5)
                rts
; End of function Boss_SunsetStingDefeatFadeOutState
; Applies defeat palette fade
Boss_SunsetStingApplyDefeatFade:                        ; CODE XREF: Boss_SunsetStingFinalDefeatState+E   p  ; was: sub_432B0
                                        ; sub_43294:loc_4329E   p
                move.w  6(a5),d0
                asr.w   #1,d0
                lea     (PaletteActiveBuffer).w,a0
                moveq   #$3F,d5                         ; '?'
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_SunsetStingApplyDefeatFade
; Advances to next state
Boss_SunsetStingNextState:                              ; CODE XREF: Boss_SunsetStingInit+D8   j  ; was: sub_432C6
                                        ; Boss_SunsetStingWaitForBattleBanner+36   j
                clr.b   4(a5)
Boss_SunsetStingIncrementState:                         ; CODE XREF: Boss_SunsetStingBrakeSegmentRotationState+1C   j  ; was: loc_432CA
                                        ; Boss_SunsetStingDefeatCoreInitializeState+1C   j
                addq.w  #2,4(a5)
Boss_SunsetStingReturn:                                 ; CODE XREF: Boss_SunsetStingInit+4   j  ; was: locret_432CE
                                        ; Boss_SunsetStingIntro+84   j
                rts
; End of function Boss_SunsetStingNextState
; Selects and mirrors a segment mapping from its angle
Boss_SunsetStingSelectSegmentMapping:                   ; CODE XREF: Boss_SunsetStingSegmentOrbitState+42   p  ; was: sub_432D0
                                        ; Boss_SunsetStingSegmentFlightState+56   p
                addi.w  #$20,d0                         ; ' '
                lsr.w   #4,d0
                andi.w  #$3C,d0                         ; '<'
                bset    #3,$E(a5)
                bclr    #4,$E(a5)
                bclr    #5,d0
                beq.s   Boss_SunsetStingSelectSegmentMappingApply
                eori.b  #$18,$E(a5)
Boss_SunsetStingSelectSegmentMappingApply:              ; CODE XREF: Boss_SunsetStingSelectSegmentMapping+1A   j  ; was: loc_432F2
                move.l  (a0,d0.w),8(a5)
                rts
; End of function Boss_SunsetStingSelectSegmentMapping
; ---------------------------------------------------------------------------
Boss_SunsetStingSegmentMappings:
                dc.l    Boss_SunsetStingSegmentMapping0  ; DATA XREF: Boss_SunsetStingSegmentOrbitState+3E   o  ; was: off_432FA
                                        ; Boss_SunsetStingSegmentFlightState+52   o
                dc.l    Boss_SunsetStingSegmentMapping1
                dc.l    Boss_SunsetStingSegmentMapping2
                dc.l    Boss_SunsetStingSegmentMapping3
                dc.l    Boss_SunsetStingSegmentMapping4
                dc.l    Boss_SunsetStingSegmentMapping5
                dc.l    Boss_SunsetStingSegmentMapping6
                dc.l    Boss_SunsetStingSegmentMapping7
Boss_SunsetStingDestroyedSegmentMappings:
                dc.l    Boss_SunsetStingDestroyedSegmentMapping0  ; DATA XREF: Boss_SunsetStingSecondarySegmentOrbitState+3E   o  ; was: off_4331A
                                        ; Boss_SunsetStingSecondarySegmentFallState+14   o
                dc.l    Boss_SunsetStingDestroyedSegmentMapping1
                dc.l    Boss_SunsetStingDestroyedSegmentMapping2
                dc.l    Boss_SunsetStingDestroyedSegmentMapping3
                dc.l    Boss_SunsetStingDestroyedSegmentMapping4
                dc.l    Boss_SunsetStingDestroyedSegmentMapping5
                dc.l    Boss_SunsetStingDestroyedSegmentMapping6
                dc.l    Boss_SunsetStingDestroyedSegmentMapping7
