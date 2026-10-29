; Terobuster state dispatch, setup, battle flow, and attack selection

Boss_TerobusterMain:                                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_38518
                tst.w   4(a5)
                beq.w   Boss_TerobusterDispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
                tst.w   8(a5)
                beq.s   Boss_TerobusterDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_TerobusterUpdatePartOscillation
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_TerobusterUpdatePartOscillation
                tst.w   (BossHealth).w
                beq.w   Boss_TerobusterBeginDefeat
Boss_TerobusterUpdatePartOscillation:                   ; CODE XREF: Boss_TerobusterMain+1A   j  ; was: loc_38544
                                        ; Boss_TerobusterMain+22   j
                lea     Boss_TerobusterPartOscillation(pc),a0
                nop
                move.w  (FrameCounter).w,d0
                asr.w   #1,d0
                andi.w  #6,d0
                move.w  (a0,d0.w),$1DE(a5)
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
Boss_TerobusterDispatchState:                           ; CODE XREF: Boss_TerobusterMain+4   j  ; was: loc_38566
                                        ; Boss_TerobusterMain+12   j
                move.w  4(a5),d0
                movea.w Boss_TerobusterStateHandlers(pc,d0.w),a0
                adda.l  #Boss_TerobusterPartOscillation,a0
                jmp     (a0)
; End of function Boss_TerobusterMain
; ---------------------------------------------------------------------------
Boss_TerobusterStateHandlers:   dc.w    Boss_TerobusterInit-Boss_TerobusterPartOscillation  ; was: off_38576
                                        ; DATA XREF: Boss_TerobusterMain+52   r
                dc.w    Boss_TerobusterSetup-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDecisionState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterHomingMissileAttackA-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterHomingMissileAttackB-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDefeatBounceState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDefeatDebrisState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDefeatFadeState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterBeginTileReveal-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterTileRevealState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDescentState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterLandingState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterStageGateDelay-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterWaitForStageReady-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterHomingMissileAttackB-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterFallingRockAttack-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDecisionState-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDefeatTimer-Boss_TerobusterPartOscillation
                dc.w    Boss_TerobusterDefeatComplete-Boss_TerobusterPartOscillation
Boss_TerobusterPartOscillation: dc.w    0, 2, 4, 2      ; DATA XREF: Boss_TerobusterMain:Boss_TerobusterUpdatePartOscillation   o  ; was: word_3859C
                                        ; Boss_TerobusterMain+56   o

; Initializes Terobuster boss clearing sprites and setting flags
Boss_TerobusterInit:                                    ; DATA XREF: ROM:Boss_TerobusterStateHandlers   o  ; was: sub_385A4
                addq.w  #2,4(a5)
                move.b  #1,(SoundFadeOutDelay).w
                move.w  #1,8(a5)
                move.w  #$B4,d0
                move.w  #$12C,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$80,$48(a5)
Boss_TerobusterSetupReturn:                             ; CODE XREF: Boss_TerobusterSetup+4   j  ; was: locret_385C8
                                        ; Boss_TerobusterSetup+A   j
                rts
; End of function Boss_TerobusterInit
; Sets up Terobuster boss with complex metasprite initialization
Boss_TerobusterSetup:                                   ; DATA XREF: ROM:00038578   o  ; was: sub_385CA
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_TerobusterSetupReturn
                subq.w  #1,$48(a5)
                bpl.s   Boss_TerobusterSetupReturn
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$A,d7
                movea.l #Boss_TerobusterMetaspriteDescriptors,a0
                movea.l #Boss_TerobusterPartRadii,a1
                movea.l #Boss_TerobusterPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$B4,(a5)
                clr.w   $54(a5)
                clr.w   $56(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $A(a5)
                move.w  #$D00,2(a5)
                move.w  #$200,$10(a5)
                move.w  #$C100,$1E2(a5)
                move.w  #$C100,$3C2(a5)
                move.w  #$10,$420(a5)
                move.w  #$8000,$422(a5)
                move.w  #$6467,$42E(a5)
                move.w  #$800,$428(a5)
                move.w  #$F4FC,$42A(a5)
                move.b  #$10,$440(a5)
                move.w  #$10,$480(a5)
                move.w  #$C000,$482(a5)
                move.w  #$B00,$48E(a5)
                move.l  #Boss_TerobusterSetupSpriteMapping,$488(a5)
                move.b  #$10,$4A0(a5)
                movea.l #Boss_TerobusterObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                lea     Boss_TerobusterTileLoadDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                bra.w   Boss_TerobusterIntro
; ---------------------------------------------------------------------------
Boss_TerobusterTileLoadDescriptor:  dc.w    $6100, $2000, $201, $2A2B, $2C2D, $2E2F  ; was: word_3868A
                                        ; DATA XREF: Boss_TerobusterSetup+B0   o
; ---------------------------------------------------------------------------
Boss_TerobusterSelectPartOrderB:                        ; CODE XREF: Boss_TerobusterDecisionState+F2   j  ; was: loc_38696
                                        ; Boss_TerobusterDecisionState+1AC   j
                move.w  #2,$A(a5)
                bra.s   Boss_TerobusterEnterDecisionState
; ---------------------------------------------------------------------------
Boss_TerobusterSelectPartOrderA:                        ; CODE XREF: Boss_TerobusterDecisionState+EE   j  ; was: loc_3869E
                                        ; Boss_TerobusterDecisionState+1A8   j
                clr.w   $A(a5)
Boss_TerobusterEnterDecisionState:                      ; CODE XREF: Boss_TerobusterSetup+D2   j  ; was: loc_386A2
                                        ; Boss_TerobusterDecisionState+286   j
                move.w  #4,4(a5)
                tst.w   (BossCombatCounter).w
                beq.s   Boss_TerobusterEnterRecoveryDecisionState
                bpl.s   Boss_TerobusterResetDecisionAnimation
Boss_TerobusterEnterRecoveryDecisionState:              ; CODE XREF: Boss_TerobusterSetup+E2   j  ; was: loc_386B0
                move.w  #$20,4(a5)                      ; ' '
Boss_TerobusterResetDecisionAnimation:                  ; CODE XREF: Boss_TerobusterSetup+E4   j  ; was: loc_386B6
                move.w  #$10,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                movea.w #(SixthEntityType-M68K_RAM),a0
                movea.w #(EleventhEntityType-M68K_RAM),a1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterBindActivePart
                exg     a0,a1
Boss_TerobusterBindActivePart:                          ; CODE XREF: Boss_TerobusterSetup+108   j  ; was: loc_386D6
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                move.w  #$14C,$14(a0)
                lea     Boss_TerobusterPoseTable(pc),a0
                nop
                bsr.w   Boss_TerobusterInitializePoseChannels
; End of function Boss_TerobusterSetup
; Waits between attacks and chooses the next state from position and RNG
Boss_TerobusterDecisionState:                           ; DATA XREF: ROM:0003857A   o  ; was: sub_386EE
                                        ; ROM:00038596   o
                cmpi.w  #$20,4(a5)                      ; ' '
                bne.s   Boss_TerobusterDecisionTick
                addi.w  #$C,(BossCombatCounter).w
                cmpi.w  #$1E0,(BossCombatCounter).w
                bmi.s   Boss_TerobusterDecisionAnimate
                move.w  #$1E0,(BossCombatCounter).w
Boss_TerobusterDecisionTick:                            ; CODE XREF: Boss_TerobusterDecisionState+6   j  ; was: loc_3870A
                subq.w  #1,$11C(a5)
                bpl.s   Boss_TerobusterDecisionAnimate
                jsr     (Physics_GetPlayerDelta).l
                addi.w  #$28,d1                         ; '('
                tst.w   d1
                bmi.s   Boss_TerobusterDecisionCheckWorldPosition
                tst.w   (DifficultyMode).w
                beq.s   Boss_TerobusterDecisionSelectAttack
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                bne.w   Boss_TerobusterBeginMissileAttackBDelayed
                bra.s   Boss_TerobusterDecisionSelectAttack
; ---------------------------------------------------------------------------
Boss_TerobusterDecisionCheckWorldPosition:              ; CODE XREF: Boss_TerobusterDecisionState+2E   j  ; was: loc_38732
                btst    #7,(FrameCounter+1).w
                beq.s   Boss_TerobusterDecisionSelectAttack
                cmpi.w  #$1180,$BC(a5)
                bmi.w   Boss_TerobusterBeginFallingRockAttack
Boss_TerobusterDecisionSelectAttack:                    ; CODE XREF: Boss_TerobusterDecisionState+34   j  ; was: loc_38744
                                        ; Boss_TerobusterDecisionState+42   j
                move.w  (RandomNumberState).w,d0
                andi.w  #1,d0
                addq.w  #1,d0
                move.w  d0,$11C(a5)
                cmpi.w  #$1190,$BC(a5)
                bpl.w   Boss_TerobusterBeginMissileAttackA
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.w   Boss_TerobusterBeginMissileAttackBDelayed
                bra.w   Boss_TerobusterBeginMissileAttackB
; ---------------------------------------------------------------------------
Boss_TerobusterDecisionAnimate:                         ; CODE XREF: Boss_TerobusterDecisionState+14   j  ; was: loc_3876C
                                        ; Boss_TerobusterDecisionState+20   j
                bsr.w   Boss_TerobusterApplyAngles
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; ---------------------------------------------------------------------------
Boss_TerobusterBeginMissileAttackA:                     ; CODE XREF: Boss_TerobusterDecisionState+6A   j  ; was: loc_38774
                move.w  #6,4(a5)
                move.w  #8,$58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $1DC(a5)
; First homing-missile pose sequence and its part-order exit
Boss_TerobusterHomingMissileAttackA:                    ; DATA XREF: ROM:0003857C   o  ; was: loc_3878A
                cmpi.w  #8,$58(a5)
                beq.s   Boss_TerobusterMissileAttackAHandlePoseEvent
                cmpi.w  #$18,$58(a5)
                bne.s   Boss_TerobusterMissileAttackAUpdate
Boss_TerobusterMissileAttackAHandlePoseEvent:           ; CODE XREF: Boss_TerobusterDecisionState+A2   j  ; was: loc_3879A
                tst.w   $1DC(a5)
                beq.s   Boss_TerobusterMissileAttackAUpdate
                move.w  #3,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                move.b  #$49,d0                         ; 'I'
                jsr     (Sound_QueueSFXRequest).l
                subi.w  #$80,(BossCombatCounter).w
                bmi.s   Boss_TerobusterMissileAttackAChooseExitOrder
                subq.w  #1,$11C(a5)
                bmi.s   Boss_TerobusterMissileAttackAChooseExitOrder
                cmpi.w  #$11A0,$BC(a5)
                bpl.s   Boss_TerobusterMissileAttackAUpdate
Boss_TerobusterMissileAttackAChooseExitOrder:           ; CODE XREF: Boss_TerobusterDecisionState+CE   j  ; was: loc_387CC
                                        ; Boss_TerobusterDecisionState+D4   j
                moveq   #8,d0
                moveq   #$18,d1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterMissileAttackAExitByPose
                exg     d0,d1
Boss_TerobusterMissileAttackAExitByPose:                ; CODE XREF: Boss_TerobusterDecisionState+E6   j  ; was: loc_387D8
                cmp.w   $58(a5),d0
                beq.w   Boss_TerobusterSelectPartOrderA
                bra.w   Boss_TerobusterSelectPartOrderB
; ---------------------------------------------------------------------------
Boss_TerobusterMissileAttackAUpdate:                    ; CODE XREF: Boss_TerobusterDecisionState+AA   j  ; was: loc_387E4
                                        ; Boss_TerobusterDecisionState+B0   j
                bsr.w   Boss_TerobusterSpawnHomingMissile
                lea     Boss_TerobusterMissileAttackAPoses(pc),a1
                nop
                bsr.w   Boss_TerobusterInterpolateAnimation
                movea.w #(SixthEntityType-M68K_RAM),a0
                movea.w #(EleventhEntityType-M68K_RAM),a1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterMissileAttackASelectPart
                exg     a0,a1
Boss_TerobusterMissileAttackASelectPart:                ; CODE XREF: Boss_TerobusterDecisionState+110   j  ; was: loc_38802
                cmpi.w  #5,$58(a5)
                bmi.s   Boss_TerobusterMissileAttackABindPart
                cmpi.w  #$18,$58(a5)
                bpl.s   Boss_TerobusterMissileAttackABindPart
                exg     a0,a1
Boss_TerobusterMissileAttackABindPart:                  ; CODE XREF: Boss_TerobusterDecisionState+11A   j  ; was: loc_38814
                                        ; Boss_TerobusterDecisionState+122   j
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                move.w  #$14C,$14(a0)
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; ---------------------------------------------------------------------------
Boss_TerobusterBeginMissileAttackBDelayed:              ; CODE XREF: Boss_TerobusterDecisionState+3E   j  ; was: loc_38826
                                        ; Boss_TerobusterDecisionState+76   j
                move.w  #$1C,4(a5)
                move.w  #8,$11C(a5)
                bra.s   Boss_TerobusterResetMissileAttackBAnimation
; ---------------------------------------------------------------------------
Boss_TerobusterBeginMissileAttackB:                     ; CODE XREF: Boss_TerobusterDecisionState+7A   j  ; was: loc_38834
                move.w  #8,4(a5)
Boss_TerobusterResetMissileAttackBAnimation:            ; CODE XREF: Boss_TerobusterDecisionState+144   j  ; was: loc_3883A
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Second homing-missile pose sequence shared by states $08 and $1C
Boss_TerobusterHomingMissileAttackB:                    ; DATA XREF: ROM:0003857E   o  ; was: loc_38844
                                        ; ROM:00038592   o
                cmpi.w  #$10,$58(a5)
                beq.s   Boss_TerobusterMissileAttackBHandlePoseEvent
                cmpi.w  #$20,$58(a5)                    ; ' '
                bne.s   Boss_TerobusterMissileAttackBUpdate
Boss_TerobusterMissileAttackBHandlePoseEvent:           ; CODE XREF: Boss_TerobusterDecisionState+15C   j  ; was: loc_38854
                tst.w   $1DC(a5)
                beq.s   Boss_TerobusterMissileAttackBUpdate
                move.w  #3,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                move.b  #$49,d0                         ; 'I'
                jsr     (Sound_QueueSFXRequest).l
                subi.w  #$80,(BossCombatCounter).w
                bmi.s   Boss_TerobusterMissileAttackBChooseExitOrder
                subq.w  #1,$11C(a5)
                bmi.s   Boss_TerobusterMissileAttackBChooseExitOrder
                cmpi.w  #$1220,$BC(a5)
                bmi.s   Boss_TerobusterMissileAttackBUpdate
Boss_TerobusterMissileAttackBChooseExitOrder:           ; CODE XREF: Boss_TerobusterDecisionState+188   j  ; was: loc_38886
                                        ; Boss_TerobusterDecisionState+18E   j
                moveq   #$10,d0
                moveq   #$20,d1                         ; ' '
                tst.w   $A(a5)
                beq.s   Boss_TerobusterMissileAttackBExitByPose
                exg     d0,d1
Boss_TerobusterMissileAttackBExitByPose:                ; CODE XREF: Boss_TerobusterDecisionState+1A0   j  ; was: loc_38892
                cmp.w   $58(a5),d0
                bne.w   Boss_TerobusterSelectPartOrderA
                bra.w   Boss_TerobusterSelectPartOrderB
; ---------------------------------------------------------------------------
Boss_TerobusterMissileAttackBUpdate:                    ; CODE XREF: Boss_TerobusterDecisionState+164   j  ; was: loc_3889E
                                        ; Boss_TerobusterDecisionState+16A   j
                bsr.w   Boss_TerobusterSpawnHomingMissile
                lea     Boss_TerobusterMissileAttackBDelayedPoseCommands(pc),a0
                nop
                lea     Boss_TerobusterMissileAttackBPoses(pc),a1
                nop
                cmpi.w  #8,4(a5)
                beq.s   Boss_TerobusterMissileAttackBSelectPoseCommands
                exg     a0,a1
Boss_TerobusterMissileAttackBSelectPoseCommands:        ; CODE XREF: Boss_TerobusterDecisionState+1C6   j  ; was: loc_388B8
                bsr.w   Boss_TerobusterInterpolateAnimation
                movea.w #(SixthEntityType-M68K_RAM),a0
                movea.w #(EleventhEntityType-M68K_RAM),a1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterMissileAttackBSelectPart
                exg     a0,a1
Boss_TerobusterMissileAttackBSelectPart:                ; CODE XREF: Boss_TerobusterDecisionState+1DA   j  ; was: loc_388CC
                cmpi.w  #$10,$58(a5)
                bmi.s   Boss_TerobusterMissileAttackBBindPart
                cmpi.w  #$20,$58(a5)                    ; ' '
                bpl.s   Boss_TerobusterMissileAttackBBindPart
                exg     a0,a1
Boss_TerobusterMissileAttackBBindPart:                  ; CODE XREF: Boss_TerobusterDecisionState+1E4   j  ; was: loc_388DE
                                        ; Boss_TerobusterDecisionState+1EC   j
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                move.w  #$14C,$14(a0)
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; ---------------------------------------------------------------------------
Boss_TerobusterBeginFallingRockAttack:                  ; CODE XREF: Boss_TerobusterDecisionState+52   j  ; was: loc_388F0
                move.w  #$1E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $1DC(a5)
                move.w  #$C800,d0
                move.w  #$C9E0,d1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterBindFallingRockAttackParts
                exg     d0,d1
Boss_TerobusterBindFallingRockAttackParts:              ; CODE XREF: Boss_TerobusterDecisionState+222   j  ; was: loc_38914
                move.w  d0,$48(a5)
                move.w  d0,$4A(a5)
                move.w  d1,$11E(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #1,d0
                move.w  d0,$11C(a5)
                move.w  #$38,$17C(a5)                   ; '8'
; Terobuster falling rock spawn phase
Boss_TerobusterFallingRockAttack:                       ; DATA XREF: ROM:00038594   o  ; was: loc_38932
                lea     Boss_TerobusterFallingRockParametersA(pc),a4
                nop
                tst.w   $11C(a5)
                bne.s   Boss_TerobusterSelectFallingRockPattern
                lea     Boss_TerobusterFallingRockParametersB(pc),a4
                nop
Boss_TerobusterSelectFallingRockPattern:                ; CODE XREF: Boss_TerobusterDecisionState+24E   j  ; was: loc_38944
                subq.w  #1,$17C(a5)
                bmi.s   Boss_TerobusterFallingRockFinale
                addi.w  #6,(BossCombatCounter).w
                cmpi.w  #$1E0,(BossCombatCounter).w
                bmi.s   Boss_TerobusterSpawnFallingRocks
                move.w  #$1E0,(BossCombatCounter).w
Boss_TerobusterSpawnFallingRocks:                       ; CODE XREF: Boss_TerobusterDecisionState+268   j  ; was: loc_3895E
                lea     Boss_TerobusterFallingRockPoses(pc),a1
                nop
                bsr.w   Boss_TerobusterInterpolateAnimation
                bsr.w   Boss_TerobusterSpawnFallingRock
                bra.s   Boss_TerobusterRenderFallingRockAttack
; ---------------------------------------------------------------------------
Boss_TerobusterFallingRockFinale:                       ; CODE XREF: Boss_TerobusterDecisionState+25A   j  ; was: loc_3896E
                subi.w  #$E,(BossCombatCounter).w
                bmi.w   Boss_TerobusterEnterDecisionState
                lea     Boss_TerobusterFallingRockFinalePoses(pc),a1
                nop
                bsr.w   Boss_TerobusterInterpolateAnimation
                bsr.w   Boss_TerobusterSpawnMultiDirectional
Boss_TerobusterRenderFallingRockAttack:                 ; CODE XREF: Boss_TerobusterDecisionState+27E   j  ; was: loc_38986
                bsr.w   Boss_TerobusterUpdateMetaspriteAndProjectile
                movea.w $48(a5),a0
                move.l  #Boss_TerobusterSecondaryRotationFrame00,8(a0)
                movea.w $11E(a5),a0
                move.w  #$14C,$14(a0)
                rts
; End of function Boss_TerobusterDecisionState
; Terobuster boss intro positioning and animation setup
Boss_TerobusterIntro:                                   ; CODE XREF: Boss_TerobusterSetup+BC   j  ; was: sub_389A2
                move.w  #$10,4(a5)
                move.w  #$196,$10(a5)
                move.w  #$60,$14(a5)                    ; '`'
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                lea     Boss_TerobusterIntroPoseChannels(pc),a0
                nop
                bsr.w   Boss_TerobusterInitializePoseChannels
                bsr.w   Boss_TerobusterInitializePaletteSequence
; End of function Boss_TerobusterIntro
; Begins the timed compressed-tile reveal used by the intro
Boss_TerobusterBeginTileReveal:                         ; DATA XREF: ROM:00038586   o  ; was: sub_389CA
                addq.w  #2,4(a5)
                move.w  #$30,$11C(a5)                   ; '0'
Boss_TerobusterRenderIntroPose:                         ; CODE XREF: Boss_TerobusterTileRevealState+12   j  ; was: loc_389D4
                bsr.w   Boss_TerobusterApplyAngles
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; End of function Boss_TerobusterBeginTileReveal
; Loads successive compressed tile records while the intro timer expires
Boss_TerobusterTileRevealState:                         ; DATA XREF: ROM:00038588   o  ; was: sub_389DC
                subq.w  #1,$11C(a5)
                bmi.s   Boss_TerobusterBeginDescent
                move.w  $11C(a5),d0
                subi.w  #$10,d0
                bsr.w   Boss_TerobusterLoadIntroTilesByIndex
                bra.s   Boss_TerobusterRenderIntroPose
; ---------------------------------------------------------------------------
Boss_TerobusterBeginDescent:                            ; CODE XREF: Boss_TerobusterTileRevealState+4   j  ; was: loc_389F0
                addq.w  #2,4(a5)
; Accelerates downward until the linked landing part reaches the floor
Boss_TerobusterDescentState:                            ; DATA XREF: ROM:0003858A   o  ; was: loc_389F4
                addi.l  #$4000,$1C(a5)
                cmpi.w  #$14C,$3D4(a5)
                bpl.s   Boss_TerobusterBeginLanding
                lea     Boss_TerobusterDescentPoses(pc),a1
                nop
                bsr.w   Boss_TerobusterInterpolateAnimation
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; ---------------------------------------------------------------------------
Boss_TerobusterBeginLanding:                            ; CODE XREF: Boss_TerobusterDescentState   j  ; was: loc_38A12
                addq.w  #2,4(a5)
                bsr.w   Boss_TerobusterInitializeLandingPose
                clr.w   $11C(a5)
; Runs the two-phase landing pose before opening the shared stage gate
Boss_TerobusterLandingState:                            ; DATA XREF: ROM:0003858C   o  ; was: loc_38A1E
                tst.w   $11C(a5)
                beq.s   Boss_TerobusterLandingBeginSecondPose
Boss_TerobusterLandingCheckComplete:                    ; CODE XREF: Boss_TerobusterLandingBeginSecondPose   j  ; was: loc_38A24
                tst.w   $58(a5)
                bmi.s   Boss_TerobusterBeginStageGateDelay
                lea     Boss_TerobusterLandingSecondPoseCommands(pc),a1
                nop
                bra.s   Boss_TerobusterUpdateLandingPose
; ---------------------------------------------------------------------------
Boss_TerobusterLandingBeginSecondPose:                  ; CODE XREF: Boss_TerobusterLandingState+4   j  ; was: loc_38A32
                tst.w   $58(a5)
                bpl.s   Boss_TerobusterSelectLandingPose
                addq.w  #1,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$4E,d0                         ; 'N'
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Boss_TerobusterLandingCheckComplete
; ---------------------------------------------------------------------------
Boss_TerobusterSelectLandingPose:                       ; CODE XREF: Boss_TerobusterLandingBeginSecondPose   j  ; was: loc_38A54
                lea     Boss_TerobusterLandingFirstPoses(pc),a1
                nop
Boss_TerobusterUpdateLandingPose:                       ; CODE XREF: Boss_TerobusterLandingCheckComplete   j  ; was: loc_38A5A
                bsr.w   Boss_TerobusterInterpolateAnimation
                bsr.w   Boss_TerobusterUpdateMetaspriteAndProjectile
                move.l  #Boss_TerobusterSecondaryRotationFrame00,$1E8(a0)
                move.l  #Boss_TerobusterSecondaryRotationFrame00,$3C8(a0)
                rts
; ---------------------------------------------------------------------------
Boss_TerobusterBeginStageGateDelay:                     ; CODE XREF: Boss_TerobusterLandingCheckComplete   j  ; was: loc_38A74
                addq.w  #2,4(a5)
                move.w  a5,$4A(a5)
                move.w  #$30,$11C(a5)                   ; '0'
                lea     Boss_TerobusterPoseTable(pc),a0
                nop
                bsr.w   Boss_TerobusterInitializePoseChannels
; End of function Boss_TerobusterLandingState
; Waits after landing before opening the shared stage UI gate
Boss_TerobusterStageGateDelay:                          ; DATA XREF: ROM:0003858E   o  ; was: sub_38A8C
                subq.w  #1,$11C(a5)
                bmi.s   Boss_TerobusterStartStageGate
                bsr.w   Boss_TerobusterApplyAngles
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; ---------------------------------------------------------------------------
Boss_TerobusterStartStageGate:                          ; CODE XREF: Boss_TerobusterStageGateDelay+4   j  ; was: loc_38A9A
                addq.w  #2,4(a5)
                moveq   #0,d0
                jsr     (BossMessage_Start).l
                move.b  #$8A,d0
                jsr     (Sound_QueueBGMRequest).l
; End of function Boss_TerobusterStageGateDelay
; Waits for the shared UI state to close before entering the battle decision state
Boss_TerobusterWaitForStageReady:                       ; DATA XREF: ROM:00038590   o  ; was: sub_38AB0
                tst.w   (MessageSequenceState).w
                bne.s   Boss_TerobusterWaitForStageReadyAnimate
                clr.b   (BossColorEffectFlags).w
                subi.w  #$A0,(CameraXLowerBound).w
                bra.w   Boss_TerobusterSelectPartOrderA
; ---------------------------------------------------------------------------
Boss_TerobusterWaitForStageReadyAnimate:                ; CODE XREF: Boss_TerobusterWaitForStageReady+4   j  ; was: loc_38AC4
                bsr.w   Boss_TerobusterApplyAngles
                bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile
; End of function Boss_TerobusterWaitForStageReady
; Enters the defeat motion when the shared boss-health value reaches zero
Boss_TerobusterBeginDefeat:                             ; CODE XREF: Boss_TerobusterMain+28   j  ; was: sub_38ACC
                move.b  #$AC,d0
                jsr     (Sound_QueueSFXRequest).l
                bset    #0,(StageTimerPauseFlag).w
                move.w  #$A,4(a5)
                move.b  #2,(BossColorEffectFlags).w
                clr.w   8(a5)
                move.w  #4,(StageSpawnCountdown).w
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #8,(PlaneBShakeLevel).w
                jsr     (Sprite_ClearObjectFlags).l
                move.l  #$20000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bmi.s   Boss_TerobusterPrepareDefeatParts
                move.l  #$FFFE0000,$18(a5)
Boss_TerobusterPrepareDefeatParts:                      ; CODE XREF: Boss_TerobusterBeginDefeat   j  ; was: loc_38B1C
                move.l  #$FFFF0000,$1C(a5)
                move.w  #$FFFF,$48(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #9,d7
Boss_TerobusterPrepareNextDefeatPart:                   ; CODE XREF: Boss_TerobusterAdvanceDefeatPart   j  ; was: loc_38B30
                btst    #7,2(a0)
                bne.s   Boss_TerobusterConvertDefeatPart
                bset    #4,2(a0)
                bra.s   Boss_TerobusterAdvanceDefeatPart
; ---------------------------------------------------------------------------
Boss_TerobusterConvertDefeatPart:                       ; CODE XREF: Boss_TerobusterPrepareNextDefeatPart   j  ; was: loc_38B40
                move.w  #$B8,(a0)
                clr.w   4(a0)
Boss_TerobusterAdvanceDefeatPart:                       ; CODE XREF: Boss_TerobusterPrepareNextDefeatPart   j  ; was: loc_38B48
                lea     $60(a0),a0
                dbf     d7,Boss_TerobusterPrepareNextDefeatPart
                move.w  #4,$422(a5)
                move.w  #4,$482(a5)
; End of function Boss_TerobusterBeginDefeat
; First attack pattern with projectile timing
