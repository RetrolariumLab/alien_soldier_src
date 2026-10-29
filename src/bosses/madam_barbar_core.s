; Dispatches Madam Barbar's main state and handles the external transition path
Boss_MadamBarbarMain:                                   ; was: sub_3A47C
                tst.w   4(a5)
                beq.w   Boss_MadamBarbarDispatchState
                tst.w   8(a5)
                beq.s   Boss_MadamBarbarDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_MadamBarbarPrepareStateDispatch
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_MadamBarbarPrepareStateDispatch
                tst.w   (BossHealth).w
                bne.s   Boss_MadamBarbarPrepareStateDispatch
                move.b  #1,(SoundFadeOutDelay).w
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #4,(StageSpawnCountdown).w
                bra.w   Boss_MadamBarbarBeginMainAttack
; ---------------------------------------------------------------------------
Boss_MadamBarbarPrepareStateDispatch:                   ; was: loc_3A4C2
                                        ; Boss_MadamBarbarMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
Boss_MadamBarbarDispatchState:                          ; was: loc_3A4D4
                                        ; Boss_MadamBarbarMain+C   j
                move.w  4(a5),d0
                movea.w Boss_MadamBarbarStateOffsets(pc,d0.w),a0
                adda.l  #Boss_MadamBarbarInitializeState,a0
                jmp     (a0)
; End of function Boss_MadamBarbarMain
; ---------------------------------------------------------------------------
Boss_MadamBarbarStateOffsets:   dc.w    Boss_MadamBarbarInitializeState-Boss_MadamBarbarInitializeState  ; was: off_3A4E4
                dc.w    Boss_MadamBarbarSetupState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarIntroApproachState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarIntroCompletionState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarWaitForPlayerSequence-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarBulletBarrageState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarPostBarrageCleanupState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarSelectAttackState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarPlayerLeftSidePoseState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarPlayerRightSidePoseState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarCenterSpinState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarDropProjectileState-Boss_MadamBarbarInitializeState
                dc.w    Boss_MadamBarbarIdleProgressState-Boss_MadamBarbarInitializeState

; Initializes Madam Barbar boss clearing sprites and setting flags
Boss_MadamBarbarInitializeState:                        ; was: sub_3A4FE
                                        ; ROM:Boss_MadamBarbarStateOffsets   o
                addq.w  #2,4(a5)
                clr.w   8(a5)
                move.w  #$118,d0
                move.w  #$12C,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #1,(SoundFadeOutDelay).w
Boss_MadamBarbarInitializationReturn:                   ; was: locret_3A51A
                rts
; End of function Boss_MadamBarbarInitializeState
; Sets up Madam Barbar boss metasprites tiles and animation
Boss_MadamBarbarSetupState:                             ; was: sub_3A51C
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_MadamBarbarInitializationReturn
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$1C,d7
                movea.l #Boss_MadamBarbarMetaspriteDescriptors,a0
                movea.l #Boss_MadamBarbarPartRadii,a1
                movea.l #Boss_MadamBarbarPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                bset    #0,$962(a5)
                bset    #0,$9C2(a5)
                bset    #0,$A22(a5)
                bset    #0,$A82(a5)
                moveq   #7,d0
                bset    d0,$18E(a5)
                bset    d0,$1EE(a5)
                bset    d0,$24E(a5)
                bset    d0,$3CE(a5)
                bset    d0,$42E(a5)
                bset    d0,$48E(a5)
                addq.w  #2,4(a5)
                move.w  #$118,(a5)
                move.w  #$CD00,2(a5)
                movea.w #(MadamBarbarWorkObject-M68K_RAM),a0
                move.l  a0,8(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$20,$20(a5)                    ; ' '
                movea.w #(MadamBarbarWorkObject-M68K_RAM),a0
                move.w  #$3A9,(a0)
                move.w  #$100,2(a0)
                move.w  #$8BA9,6(a0)
                move.w  #$100,8(a0)
                move.w  #1,$17E(a5)
                move.w  #$248,$9D0(a5)
                movea.l #Boss_MadamBarbarObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                movea.l #Boss_MadamBarbarTileLoadCommands,a0
                jsr     (Tilemap_QueueIndexedRows).l
                bsr.w   Boss_MadamBarbarApplyPartFlagArrangement
                bsr.w   Boss_MadamBarbarUpdateWobble
                lea     Boss_MadamBarbarPoseTable(pc),a0
                nop
                bsr.w   Boss_MadamBarbarInitializePoseChannels
                bra.s   Boss_MadamBarbarIntroApproachState
; End of function Boss_MadamBarbarSetupState
; ---------------------------------------------------------------------------
Boss_MadamBarbarTileLoadCommands:   dc.w    $6100, $2000, $302, $2021, $2223, $2425, $2627, $28, $2900  ; was: word_3A5F2

; Boss introduction sequence checking position for battle start
Boss_MadamBarbarIntroApproachState:                     ; was: sub_3A604
                tst.w   $17E(a5)
                bpl.w   Boss_MadamBarbarUpdatePlayerLeftSidePose
                move.w  #3,$17E(a5)
                cmpi.w  #$5C0,$BC(a5)
                bpl.w   Boss_MadamBarbarUpdatePlayerLeftSidePose
                addq.w  #2,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #7,$17E(a5)
; Madam Barbar intro sequence ending at the shared boss-message gate
Boss_MadamBarbarIntroCompletionState:                   ; was: loc_3A640
                tst.w   $17E(a5)
                bpl.s   Boss_MadamBarbarUpdateIntroPose
                addq.w  #2,4(a5)
                moveq   #6,d0
                jsr     (BossMessage_Start).l
                move.b  #$8A,d0
                jsr     (Sound_QueueBGMOrStop).l
Boss_MadamBarbarUpdateIntroPose:                        ; was: loc_3A65C
                                        ; Boss_MadamBarbarWaitForPlayerSequence+8   j
                lea     Boss_MadamBarbarIntroIdlePoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bra.w   Boss_MadamBarbarUpdateParts
; End of function Boss_MadamBarbarIntroApproachState
; Waits for the player/UI sequence before entering the AI state
Boss_MadamBarbarWaitForPlayerSequence:                  ; was: sub_3A66A
                bsr.w   Boss_MadamBarbarSpawnAnimationEffect
                tst.w   (MessageSequenceState).w
                bne.s   Boss_MadamBarbarUpdateIntroPose
                clr.b   (BossColorEffectFlags).w
                subi.w  #$A0,(CameraXLowerBound).w
                bra.w   Boss_MadamBarbarBeginAIState
; ---------------------------------------------------------------------------
Boss_MadamBarbarBeginMainAttack:                        ; was: loc_3A682
                move.w  #$A,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$11F,$11C(a5)
                move.w  #$48,(ExplosionSoundDelay).w    ; 'H'
; Runs the timed bullet barrage and flashes linked parts near its end
Boss_MadamBarbarBulletBarrageState:                     ; was: loc_3A6AE
                subq.w  #1,$11C(a5)
                bpl.s   Boss_MadamBarbarUpdateBulletBarrage
                addq.w  #2,4(a5)
                move.w  #$30,$11C(a5)                   ; '0'
Boss_MadamBarbarUpdateBulletBarrage:                    ; was: loc_3A6BE
                bsr.w   Boss_MadamBarbarSpawnBarrageParticle
                lea     Boss_MadamBarbarBulletBarragePoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bsr.w   Boss_MadamBarbarUpdateParts
                cmpi.w  #$38,$11C(a5)                   ; '8'
                bpl.s   Boss_MadamBarbarBulletBarrageReturn
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_MadamBarbarDisableAllPartFlag7
                moveq   #7,d0
                moveq   #$1C,d7
                movea.w a5,a0
Boss_MadamBarbarEnableAllPartFlag7:                     ; was: loc_3A6E8
                bset    d0,2(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarEnableAllPartFlag7
Boss_MadamBarbarBulletBarrageReturn:                    ; was: locret_3A6F4
                rts
; End of function Boss_MadamBarbarBulletBarrageState
; Updates linked parts and clears the object range after the barrage
Boss_MadamBarbarPostBarrageCleanupState:                ; was: sub_3A6F6
                subq.w  #1,$11C(a5)
                bpl.s   Boss_MadamBarbarUpdatePostBarrageParts
                moveq   #0,d0
                move.w  #$12C,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
Boss_MadamBarbarUpdatePostBarrageParts:                 ; was: loc_3A708
                bsr.w   Boss_MadamBarbarUpdateParts
Boss_MadamBarbarDisableAllPartFlag7:                    ; was: loc_3A70C
                move.w  #$FEB0,(SecondaryCameraXPos).w
                moveq   #7,d0
                moveq   #$1C,d7
                movea.w a5,a0
Boss_MadamBarbarDisableNextPartFlag7:                   ; was: loc_3A718
                bclr    d0,2(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarDisableNextPartFlag7
                rts
; End of function Boss_MadamBarbarPostBarrageCleanupState
; Initialize Madam Barbar idle state with position and timers
Boss_MadamBarbarBeginIdleState:                         ; was: sub_3A726
                                        ; Boss_MadamBarbarSelectAttackState+F6   j
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$18,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                clr.w   $17E(a5)
; End of function Boss_MadamBarbarBeginIdleState
; Advances shared progress and the idle pose until the AI state begins
Boss_MadamBarbarIdleProgressState:                      ; was: sub_3A74A
                tst.w   $17E(a5)
                bpl.s   Boss_MadamBarbarUpdateIdleProgress
                clr.w   $17E(a5)
                cmpi.w  #$1E0,(BossCombatCounter).w
                bpl.w   Boss_MadamBarbarPrepareAIState
Boss_MadamBarbarUpdateIdleProgress:                     ; was: loc_3A75E
                addi.w  #2,(BossCombatCounter).w
                bsr.w   Boss_MadamBarbarSpawnAnimationEffect
                lea     Boss_MadamBarbarIntroIdlePoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bra.w   Boss_MadamBarbarUpdateParts
; ---------------------------------------------------------------------------
Boss_MadamBarbarPrepareAIState:                         ; was: loc_3A776
                                        ; Boss_MadamBarbarSelectAttackState+8A   j
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_MadamBarbarBeginAIState:                           ; was: loc_3A780
                move.w  #$E,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                move.w  #1,$17E(a5)
; End of function Boss_MadamBarbarIdleProgressState
; Selects the next pose state from player distance, side, and frame-derived bits
Boss_MadamBarbarSelectAttackState:                      ; was: sub_3A79C
                tst.w   $17E(a5)
                bpl.s   Boss_MadamBarbarUpdateAttackSelectionPose
                move.w  (RandomNumberState).w,d7
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                move.w  d0,d1
                bpl.s   Boss_MadamBarbarCheckAttackDistance
                neg.w   d1
Boss_MadamBarbarCheckAttackDistance:                    ; was: loc_3A7B4
                cmpi.w  #$70,d1                         ; 'p'
                bpl.s   Boss_MadamBarbarCheckMediumRangeAttack
                andi.w  #$3000,d7
                bne.w   Boss_MadamBarbarBeginCenterSpin
                bra.w   Boss_MadamBarbarBeginDropProjectileState
; ---------------------------------------------------------------------------
Boss_MadamBarbarCheckMediumRangeAttack:                 ; was: loc_3A7C6
                cmpi.w  #$100,d1
                bpl.s   Boss_MadamBarbarSelectPlayerSidePose
                andi.w  #$7000,d7
                beq.w   Boss_MadamBarbarBeginDropProjectileState
Boss_MadamBarbarSelectPlayerSidePose:                   ; was: loc_3A7D4
                tst.w   d0
                bpl.w   Boss_MadamBarbarBeginPlayerRightSidePose
                bra.w   Boss_MadamBarbarBeginPlayerLeftSidePose
; ---------------------------------------------------------------------------
Boss_MadamBarbarUpdateAttackSelectionPose:              ; was: loc_3A7DE
                lea     Boss_MadamBarbarIntroIdlePoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bra.w   Boss_MadamBarbarUpdateParts
; ---------------------------------------------------------------------------
Boss_MadamBarbarBeginPlayerLeftSidePose:                ; was: loc_3A7EC
                move.w  #$10,4(a5)
                clr.w   $58(a5)
                clr.w   6(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #1,$17E(a5)
; Runs the pose selected when the player was left of the boss
Boss_MadamBarbarPlayerLeftSidePoseState:                ; was: loc_3A806
                bsr.w   Boss_MadamBarbarSpawnDebris
                tst.w   $17E(a5)
                bpl.s   Boss_MadamBarbarUpdatePlayerLeftSidePose
                subi.w  #0,(BossCombatCounter).w
                bmi.w   Boss_MadamBarbarBeginIdleState
                move.w  (PlayerXPosition).w,d0
                addi.w  #$60,d0                         ; '`'
                cmp.w   $10(a5),d0
                bpl.w   Boss_MadamBarbarPrepareAIState
                move.w  #3,$17E(a5)
Boss_MadamBarbarUpdatePlayerLeftSidePose:               ; was: loc_3A830
                                        ; Boss_MadamBarbarIntroApproachState+14   j
                lea     Boss_MadamBarbarPlayerLeftPoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bsr.w   Boss_MadamBarbarPlayRotationSound
                movea.w #(TwentySixthEntityType-M68K_RAM),a0
                cmpi.w  #8,$58(a5)
                beq.s   Boss_MadamBarbarAnchorPlayerLeftSidePose
                cmpi.w  #$C,$58(a5)
                beq.s   Boss_MadamBarbarAnchorPlayerLeftSidePose
                movea.w #(TwentySeventhEntityType-M68K_RAM),a0
Boss_MadamBarbarAnchorPlayerLeftSidePose:               ; was: loc_3A856
                                        ; Boss_MadamBarbarSelectAttackState+B4   j
                move.w  #$C8,$14(a0)
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                bra.w   Boss_MadamBarbarUpdateParts
; ---------------------------------------------------------------------------
Boss_MadamBarbarBeginPlayerRightSidePose:               ; was: loc_3A868
                move.w  #$12,4(a5)
                clr.w   $58(a5)
                clr.w   6(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #1,$17E(a5)
; Runs the pose selected when the player was right of the boss
Boss_MadamBarbarPlayerRightSidePoseState:               ; was: loc_3A882
                bsr.w   Boss_MadamBarbarSpawnDebris
                tst.w   $17E(a5)
                bpl.s   Boss_MadamBarbarUpdatePlayerRightSidePose
                subi.w  #0,(BossCombatCounter).w
                bmi.w   Boss_MadamBarbarBeginIdleState
                move.w  (PlayerXPosition).w,d0
                subi.w  #$60,d0                         ; '`'
                cmp.w   $10(a5),d0
                bmi.w   Boss_MadamBarbarPrepareAIState
                move.w  #3,$17E(a5)
Boss_MadamBarbarUpdatePlayerRightSidePose:              ; was: loc_3A8AC
                lea     Boss_MadamBarbarPlayerRightPoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bsr.w   Boss_MadamBarbarPlayRotationSound
                movea.w #(TwentyEighthEntityType-M68K_RAM),a0
                cmpi.w  #4,$58(a5)
                beq.s   Boss_MadamBarbarAnchorPlayerRightSidePose
                cmpi.w  #$10,$58(a5)
                beq.s   Boss_MadamBarbarAnchorPlayerRightSidePose
                movea.w #(TwentyNinthEntityType-M68K_RAM),a0
Boss_MadamBarbarAnchorPlayerRightSidePose:              ; was: loc_3A8D2
                                        ; Boss_MadamBarbarSelectAttackState+130   j
                move.w  #$C8,$14(a0)
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                bra.w   Boss_MadamBarbarUpdateParts
; ---------------------------------------------------------------------------
Boss_MadamBarbarBeginCenterSpin:                        ; was: loc_3A8E4
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$14,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                clr.w   $11E(a5)
; Runs the center-spin pose and updates its linked-part parameters
Boss_MadamBarbarCenterSpinState:                        ; was: loc_3A908
                bsr.w   Boss_MadamBarbarSpawnDebris
                move.w  $58(a5),d0
                bpl.s   Boss_MadamBarbarCheckCenterSpinTrigger
                tst.w   (BossCombatCounter).w
                bmi.w   Boss_MadamBarbarBeginIdleState
                bra.w   Boss_MadamBarbarPrepareAIState
; ---------------------------------------------------------------------------
Boss_MadamBarbarCheckCenterSpinTrigger:                 ; was: loc_3A91E
                tst.w   $11E(a5)
                bne.s   Boss_MadamBarbarSelectCenterSpinPartValue
                cmpi.w  #$C,d0
                bne.s   Boss_MadamBarbarSelectCenterSpinPartValue
                subi.w  #$52,(BossCombatCounter).w      ; 'R'
                addq.w  #1,$11E(a5)
                move.b  #$B2,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  $58(a5),d0
Boss_MadamBarbarSelectCenterSpinPartValue:              ; was: loc_3A942
                                        ; Boss_MadamBarbarSelectAttackState+18C   j
                move.w  #$86,d1
                cmpi.w  #$C,d0
                bmi.s   Boss_MadamBarbarUpdateCenterSpinParameters
                cmpi.w  #$14,d0
                bpl.s   Boss_MadamBarbarUpdateCenterSpinParameters
                move.w  #$FF,d1
Boss_MadamBarbarUpdateCenterSpinParameters:             ; was: loc_3A956
                                        ; Boss_MadamBarbarSelectAttackState+1B4   j
                move.w  d1,$1A6(a5)
                move.w  d1,$3E6(a5)
                move.w  $1DC(a5),d1
                move.w  $1DE(a5),d2
                cmpi.w  #$C,d0
                bmi.s   Boss_MadamBarbarIncreaseCenterSpinAngles
                cmpi.w  #$10,d1
                bmi.s   Boss_MadamBarbarStoreCenterSpinAngles
                subq.w  #4,d1
                subq.w  #4,d2
                bra.s   Boss_MadamBarbarStoreCenterSpinAngles
; ---------------------------------------------------------------------------
Boss_MadamBarbarIncreaseCenterSpinAngles:               ; was: loc_3A978
                cmpi.w  #$60,d1                         ; '`'
                bpl.s   Boss_MadamBarbarStoreCenterSpinAngles
                addq.w  #4,d1
                addq.w  #4,d2
Boss_MadamBarbarStoreCenterSpinAngles:                  ; was: loc_3A982
                                        ; Boss_MadamBarbarSelectAttackState+1DA   j
                andi.w  #$1FE,d1
                andi.w  #$1FE,d2
                move.w  d1,$1DC(a5)
                move.w  d2,$1DE(a5)
                lea     Boss_MadamBarbarCenterSpinPoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bra.w   Boss_MadamBarbarApplyPartLayout
; ---------------------------------------------------------------------------
Boss_MadamBarbarBeginDropProjectileState:               ; was: loc_3A9A0
                                        ; Boss_MadamBarbarSelectAttackState+34   j
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$16,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CFE0,$4A(a5)
                move.w  #$C8,$9D4(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$1E,d0
                addq.w  #7,d0
                move.w  d0,$17E(a5)
; Runs the bounded drop-projectile pose
Boss_MadamBarbarDropProjectileState:                    ; was: loc_3A9CE
                subi.w  #1,(BossCombatCounter).w
                bmi.w   Boss_MadamBarbarBeginIdleState
                tst.w   $17E(a5)
                bmi.w   Boss_MadamBarbarPrepareAIState
                bsr.w   Boss_MadamBarbarSpawnDropProjectile
                lea     Boss_MadamBarbarDropProjectilePoses(pc),a1
                nop
                bsr.w   Boss_MadamBarbarUpdatePose
                bra.w   *+4
; End of function Boss_MadamBarbarSelectAttackState
; Updates all boss body parts positions with offset calculations
Boss_MadamBarbarUpdateParts:                            ; was: sub_3A9F2
                                        ; Boss_MadamBarbarBulletBarrageState+62   p
                bsr.w   Boss_MadamBarbarUpdateRotationBounds
Boss_MadamBarbarApplyPartLayout:                        ; was: loc_3A9F6
                moveq   #$1B,d7
                jsr     (Sprite_SetMetaspriteTraversalPointers).l
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #$24,d0                         ; '$'
                moveq   #$A,d1
                moveq   #5,d7
Boss_MadamBarbarOffsetPositiveXPositiveYGroup:          ; was: loc_3AA08
                add.w   d0,$40(a0)
                add.w   d1,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetPositiveXPositiveYGroup
                moveq   #5,d7
Boss_MadamBarbarOffsetNegativeXPositiveYGroup:          ; was: loc_3AA1A
                sub.w   d0,$40(a0)
                add.w   d1,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetNegativeXPositiveYGroup
                moveq   #$28,d0                         ; '('
                moveq   #$28,d1                         ; '('
                moveq   #$14,d2
                moveq   #2,d7
Boss_MadamBarbarOffsetNegativeXNegativeYGroupA:         ; was: loc_3AA32
                sub.w   d0,$40(a0)
                sub.w   d2,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetNegativeXNegativeYGroupA
                moveq   #2,d7
Boss_MadamBarbarOffsetNegativeXNegativeYGroupB:         ; was: loc_3AA44
                sub.w   d1,$40(a0)
                sub.w   d2,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetNegativeXNegativeYGroupB
                moveq   #2,d7
Boss_MadamBarbarOffsetPositiveXNegativeYGroupA:         ; was: loc_3AA56
                add.w   d0,$40(a0)
                sub.w   d2,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetPositiveXNegativeYGroupA
                moveq   #2,d7
Boss_MadamBarbarOffsetPositiveXNegativeYGroupB:         ; was: loc_3AA68
                add.w   d1,$40(a0)
                sub.w   d2,$44(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MadamBarbarOffsetPositiveXNegativeYGroupB
                movea.w a5,a3
                moveq   #$1C,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bsr.w   Boss_MadamBarbarPublishScreenPosition
; End of function Boss_MadamBarbarUpdateParts
; Applies the frame-indexed wobble offsets to the root object
Boss_MadamBarbarUpdateWobble:                           ; was: sub_3AA86
                move.w  (FrameCounter).w,d7
                andi.w  #$F,d7
                move.b  Boss_MadamBarbarWobbleOffsets(pc,d7.w),d0
                addq.w  #8,d7
                andi.w  #$F,d7
                move.b  Boss_MadamBarbarWobbleOffsets(pc,d7.w),d1
                move.w  #$24EA,(MadamWobbleX).w
                move.w  #$240E,(MadamWobbleY).w
                sub.b   d0,(MadamWobbleX).w
                sub.b   d1,(MadamWobbleY).w
                asr.b   #1,d0
                asr.b   #1,d1
                add.b   d0,(MadamWobbleX+1).w
                sub.b   d1,(MadamWobbleX+3).w
                movea.w #(MadamBarbarWorkObject-M68K_RAM),a0
                move.w  (MadamWobbleX).w,4(a0)
                move.w  (MadamWobbleY).w,$A(a0)
                rts
; End of function Boss_MadamBarbarUpdateWobble
; ---------------------------------------------------------------------------
Boss_MadamBarbarWobbleOffsets:  dc.b    0, 1, 2, 3, 4, 4, 4, 4, 3, 2, 1, 0, 0, 1, 1, 0  ; was: byte_3AACE
                                        ; Boss_MadamBarbarUpdateWobble+12   r

; Calculate direction to player and set Madam Barbar facing
Boss_MadamBarbarUpdateFacingAndPartFlags:
                clr.w   $54(a5)                         ; was: sub_3AADE
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_MadamBarbarApplyPartFlagArrangement
                move.w  #$100,$54(a5)
; End of function Boss_MadamBarbarUpdateFacingAndPartFlags
; Applies the fixed bit-three arrangement to eight linked parts
Boss_MadamBarbarApplyPartFlagArrangement:               ; was: sub_3AAF2
                                        ; Boss_MadamBarbarUpdateFacingAndPartFlags+C   j
                moveq   #3,d5
                bclr    d5,$6E(a5)
                bclr    d5,$CE(a5)
                bclr    d5,$12E(a5)
                bclr    d5,$18E(a5)
                bset    d5,$2AE(a5)
                bset    d5,$30E(a5)
                bset    d5,$36E(a5)
                bset    d5,$3CE(a5)
                rts
; End of function Boss_MadamBarbarApplyPartFlagArrangement
; Updates the two bounded rotation-control words
Boss_MadamBarbarUpdateRotationBounds:                   ; was: sub_3AB16
                movea.w #(FifthEntityWork5C-M68K_RAM),a0
                bsr.s   Boss_MadamBarbarUpdateRotationBound
                movea.w #(FifthEntityWork5E-M68K_RAM),a0
; End of function Boss_MadamBarbarUpdateRotationBounds
; Moves one rotation-control word between limits 8 and $20
Boss_MadamBarbarUpdateRotationBound:                    ; was: sub_3AB20
                btst    #2,(FrameCounter+1).w
                bne.s   Boss_MadamBarbarIncreaseRotationBound
                subq.w  #8,(a0)
                cmpi.w  #8,(a0)
                bpl.s   Boss_MadamBarbarWrapRotationBound
                move.w  #8,(a0)
Boss_MadamBarbarWrapRotationBound:                      ; was: loc_3AB34
                                        ; Boss_MadamBarbarUpdateRotationBound+20   j
                andi.w  #$1FC,(a0)
                rts
; ---------------------------------------------------------------------------
Boss_MadamBarbarIncreaseRotationBound:                  ; was: loc_3AB3A
                addq.w  #8,(a0)
                cmpi.w  #$20,(a0)                       ; ' '
                bmi.s   Boss_MadamBarbarWrapRotationBound
                move.w  #$20,(a0)                       ; ' '
                andi.w  #$1FC,(a0)
Boss_MadamBarbarRotationHelperReturn:                   ; was: locret_3AB4A
                                        ; Boss_MadamBarbarPlayRotationSound+C   j
                rts
; End of function Boss_MadamBarbarUpdateRotationBound
; Play rotation sound effect for Madam Barbar based on animation frame
Boss_MadamBarbarPlayRotationSound:                      ; was: sub_3AB4C
                                        ; Boss_MadamBarbarSelectAttackState+11A   p
                tst.w   $29C(a5)
                beq.s   Boss_MadamBarbarRotationHelperReturn
                btst    #0,7(a5)
                bne.s   Boss_MadamBarbarRotationHelperReturn
                move.b  #$AF,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Boss_MadamBarbarPlayRotationSound
; Publishes and clamps the boss-relative shared screen position
Boss_MadamBarbarPublishScreenPosition:                  ; was: sub_3AB64
                move.w  #$BC,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$50,d0                         ; 'P'
                move.w  d0,(SecondaryCameraYPos).w
                jmp     Boss_ClampSharedScreenPosition
; End of function Boss_MadamBarbarPublishScreenPosition
; Spawns a type-A4 particle with randomized position and horizontal velocity
Boss_MadamBarbarSpawnBarrageParticle:                   ; was: sub_3AB82
                move.w  #6,(PlaneAShakeLevel).w
                move.w  #6,(PlaneBShakeLevel).w
                jsr     (Projectile_PrepareImpactSpawnAfterDelay).l
                bne.s   Boss_MadamBarbarSpawnBarrageParticleReturn
                jsr     (Sprite_InitTypeA4FromTable).l
                move.b  #0,$20(a0)
                move.w  #1,$1C(a0)
                move.w  (RandomNumberState+2).w,$1E(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$7F,d0
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$40,d0                         ; '@'
                subi.w  #$1D,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
Boss_MadamBarbarSpawnBarrageParticleReturn:             ; was: locret_3ABE2
                rts
; End of function Boss_MadamBarbarSpawnBarrageParticle
; Interprets one pose-command stream and publishes linked-part angles
Boss_MadamBarbarUpdatePose:                             ; was: sub_3ABE4
                                        ; Boss_MadamBarbarBulletBarrageState+5E   p
                clr.w   $29C(a5)
                tst.w   $C(a5)
                bpl.s   Boss_MadamBarbarAdvancePoseInterpolation
Boss_MadamBarbarReadNextPoseCommand:                    ; was: loc_3ABEE
                move.w  $58(a5),d0
                bmi.w   Boss_MadamBarbarPublishPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_MadamBarbarReadPoseControlWord
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_MadamBarbarReadPoseControlWord:                    ; was: loc_3AC10
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_MadamBarbarCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_MadamBarbarCheckPoseLoopCommand:                   ; was: loc_3AC20
                cmpi.w  #$FFFF,d3
                bne.s   Boss_MadamBarbarStartPoseInterpolation
                clr.w   $58(a5)
                clr.w   6(a5)
                bra.s   Boss_MadamBarbarReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_MadamBarbarStartPoseInterpolation:                 ; was: loc_3AC30
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_MadamBarbarPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_MadamBarbarCalculatePoseDeltas
                move.b  (PoseDurationByte).w,d1
                ext.w   d1
                add.w   d1,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,6(a5)
                addq.w  #1,$29C(a5)
                subq.w  #1,$17E(a5)
                tst.w   $C(a5)
                bmi.s   Boss_MadamBarbarPublishPoseAngles
Boss_MadamBarbarAdvancePoseInterpolation:               ; was: loc_3AC6A
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$B,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_MadamBarbarPublishPoseAngles:                      ; was: loc_3AC7A
                                        ; Boss_MadamBarbarUpdatePose+84   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$176(a5)
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                move.w  $1DC(a5),d2
                move.w  d2,d1
                neg.w   d1
                add.w   d0,d2
                add.w   d0,d1
                and.w   d7,d1
                and.w   d7,d1
                move.w  d2,$236(a5)
                move.w  d1,$296(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                move.b  $C(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                move.w  $1DE(a5),d2
                move.w  d2,d1
                neg.w   d1
                add.w   d0,d2
                add.w   d0,d1
                and.w   d7,d1
                and.w   d7,d1
                move.w  d2,$476(a5)
                move.w  d1,$4D6(a5)
                move.b  $10(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$536(a5)
                move.w  d1,$596(a5)
                move.b  $14(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$5F6(a5)
                move.w  d0,$9B6(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                move.w  d0,$A16(a5)
                move.b  $20(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$776(a5)
                move.w  d1,$7D6(a5)
                move.b  $24(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$836(a5)
                move.w  d0,$A76(a5)
                move.b  $28(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$896(a5)
                move.w  d1,$8F6(a5)
                move.b  $2C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$956(a5)
                move.w  d0,$AD6(a5)
                rts
; End of function Boss_MadamBarbarUpdatePose
; Calculates the 12 channel deltas toward the selected pose target
Boss_MadamBarbarCalculatePoseDeltas:                    ; was: sub_3AD8E
                lea     (Boss_MadamBarbarNeutralPose).l,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #$B,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_MadamBarbarCalculatePoseDeltas
; Initializes the 12 fixed-point pose channels from the first target record
Boss_MadamBarbarInitializePoseChannels:                 ; was: sub_3ADA4
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                moveq   #$B,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_MadamBarbarInitializePoseChannels
; Spawns debris projectiles with random velocity and trajectory
Boss_MadamBarbarSpawnDebris:                            ; was: sub_3ADB0
                                        ; Boss_MadamBarbarSelectAttackState:Boss_MadamBarbarPlayerRightSidePoseState   p
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Boss_MadamBarbarSpawnDebrisReturn
                movea.w #(FortySixthEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward8).l
                bne.s   Boss_MadamBarbarSpawnDebrisReturn
                move.w  #$120,(a0)
                clr.w   4(a0)
                move.w  #$8D00,2(a0)
                move.w  #$F3B3,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.b  #4,$20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                subq.w  #1,$14(a0)
                move.b  #$80,$21(a0)
                move.l  #$F40CF40C,$28(a0)
                move.w  #$20,$48(a0)                    ; ' '
                clr.w   $4A(a0)
                moveq   #3,d0
                swap    d0
                btst    #4,(RandomNumberState).w
                beq.s   Boss_MadamBarbarApplyDebrisDirection
                neg.l   d0
Boss_MadamBarbarApplyDebrisDirection:                   ; was: loc_3AE22
                move.l  d0,$4C(a0)
                asr.l   #1,d0
                move.l  d0,$18(a0)
                move.l  #$18000,$1C(a0)
Boss_MadamBarbarSpawnDebrisReturn:                      ; was: locret_3AE34
                                        ; Boss_MadamBarbarSpawnDebris+14   j
                rts
; End of function Boss_MadamBarbarSpawnDebris
