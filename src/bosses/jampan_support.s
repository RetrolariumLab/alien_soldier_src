; Jampan tracking, shield, offset-attack, and linked-object controllers

; Steps the controller horizontally toward the player once or twice per frame
Boss_JampanTrackPlayerX:                                ; CODE XREF: Boss_JampanSelectAttackState   p  ; was: sub_4A07E
                                        ; sub_498F2   p
                bsr.s   Boss_JampanStepTowardPlayerX
                tst.w   (DifficultyMode).w
                beq.s   Boss_JampanTrackPlayerXReturn
                bsr.s   Boss_JampanStepTowardPlayerX
Boss_JampanTrackPlayerXReturn:                          ; CODE XREF: Boss_JampanTrackPlayerX+6   j  ; was: locret_4A088
                rts
; End of function Boss_JampanTrackPlayerX
; Moves controller X one pixel toward the player's X coordinate
Boss_JampanStepTowardPlayerX:                           ; CODE XREF: Boss_JampanTrackPlayerX   p  ; was: sub_4A08A
                                        ; Boss_JampanTrackPlayerX+8   p
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                beq.s   Boss_JampanStepTowardPlayerXReturn
                tst.w   d0
                bmi.s   Boss_JampanUseLeftwardTrackingStep
                move.w  #1,d1
                bra.s   Boss_JampanApplyPlayerXTrackingStep
; ---------------------------------------------------------------------------
Boss_JampanUseLeftwardTrackingStep:                     ; CODE XREF: Boss_JampanStepTowardPlayerX+C   j  ; was: loc_4A09E
                move.w  #$FFFF,d1
Boss_JampanApplyPlayerXTrackingStep:                    ; CODE XREF: Boss_JampanStepTowardPlayerX+12   j  ; was: loc_4A0A2
                add.w   d1,$10(a5)
Boss_JampanStepTowardPlayerXReturn:                     ; CODE XREF: Boss_JampanStepTowardPlayerX+8   j  ; was: locret_4A0A6
                rts
; End of function Boss_JampanStepTowardPlayerX
; Adjusts Y position to track player
Boss_JampanTrackPlayerY:                                ; CODE XREF: Boss_JampanTrackPlayerDuringAlternatePatternState+8   p  ; was: sub_4A0A8
                move.w  (PlayerYPosition).w,d0
                sub.w   $14(a5),d0
                beq.s   Boss_JampanTrackPlayerYReturn
                tst.w   d0
                bmi.s   Boss_JampanUseUpwardTrackingStep
                move.w  #1,d1
                bra.s   Boss_JampanApplyPlayerYTrackingStep
; ---------------------------------------------------------------------------
Boss_JampanUseUpwardTrackingStep:                       ; CODE XREF: Boss_JampanTrackPlayerY+C   j  ; was: loc_4A0BC
                move.w  #$FFFF,d1
Boss_JampanApplyPlayerYTrackingStep:                    ; CODE XREF: Boss_JampanTrackPlayerY+12   j  ; was: loc_4A0C0
                add.w   d1,$14(a5)
Boss_JampanTrackPlayerYReturn:                          ; CODE XREF: Boss_JampanTrackPlayerY+8   j  ; was: locret_4A0C4
                rts
; End of function Boss_JampanTrackPlayerY
; Converges the shared aim offset on an angle derived from the player position
Boss_JampanTrackPlayerAimOffset:                        ; CODE XREF: Boss_JampanSelectAttackState+4   p  ; was: sub_4A0C6
                                        ; sub_49992   p
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                asr.w   #2,d0
                cmpi.w  #$100,d2
                bcc.s   Boss_JampanConvergePlayerAimOffset
                neg.w   d0
Boss_JampanConvergePlayerAimOffset:                     ; CODE XREF: Boss_JampanTrackPlayerAimOffset+16   j  ; was: loc_4A0E0
                move.w  (SharedScratchLong9+2).w,d1
                sub.w   d1,d0
                beq.s   Boss_JampanTrackPlayerAimOffsetReturn
                tst.w   d0
                bmi.s   Boss_JampanDecreasePlayerAimOffset
                addq.w  #1,(SharedScratchLong9+2).w
                bra.s   Boss_JampanTrackPlayerAimOffsetReturn
; ---------------------------------------------------------------------------
Boss_JampanDecreasePlayerAimOffset:                     ; CODE XREF: Boss_JampanTrackPlayerAimOffset+24   j  ; was: loc_4A0F2
                subq.w  #1,(SharedScratchLong9+2).w
Boss_JampanTrackPlayerAimOffsetReturn:                  ; CODE XREF: Boss_JampanTrackPlayerAimOffset+20   j  ; was: locret_4A0F6
                                        ; Boss_JampanTrackPlayerAimOffset+2A   j
                rts
; End of function Boss_JampanTrackPlayerAimOffset
; Converges the shared vertical orbit offset on controller Y minus $F0
Boss_JampanTrackVerticalOrbitOffset:                    ; CODE XREF: Boss_JampanWaitForOpeningSidePartState   p  ; was: sub_4A0F8
                                        ; sub_49666   p
                move.w  $14(a5),d0
                subi.w  #$F0,d0
                sub.w   (SharedScratchLong10).w,d0
                beq.s   Boss_JampanTrackVerticalOrbitOffsetReturn
                tst.w   d0
                bmi.s   Boss_JampanDecreaseVerticalOrbitOffset
                addq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanDecreaseVerticalOrbitOffset:                 ; CODE XREF: Boss_JampanTrackVerticalOrbitOffset+10   j  ; was: loc_4A110
                subq.w  #1,(SharedScratchLong10).w
Boss_JampanTrackVerticalOrbitOffsetReturn:              ; CODE XREF: Boss_JampanTrackVerticalOrbitOffset+C   j  ; was: locret_4A114
                rts
; End of function Boss_JampanTrackVerticalOrbitOffset
; Reserved no-op hook in the attack-selection update path
Boss_JampanAttackSelectionNoOpHook:                     ; CODE XREF: Boss_JampanSelectAttackState+C   p  ; was: nullsub_97
                rts
; End of function Boss_JampanAttackSelectionNoOpHook

; Enables all 6 shield entities
Boss_JampanEnableShields:                               ; CODE XREF: Boss_JampanShieldCycleDelayState+12   p  ; was: sub_4A118
                                        ; Boss_JampanWaitForAlternatePatternAngleState+10   p
                move.w  #5,d7
                movea.w #(TwentyThirdEntityType-M68K_RAM),a0
Boss_JampanEnableShieldLoop:                            ; CODE XREF: Boss_JampanEnableShields+12   j  ; was: loc_4A120
                ori.w   #$8000,2(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JampanEnableShieldLoop
                move.b  #$40,(TwentyThirdEntityStatus).w  ; '@'
                move.w  #$A0,(TwentyThirdEntityWork26).w
                move.l  #$F808F808,(TwentyThirdEntityWork2C).w
                rts
; End of function Boss_JampanEnableShields
; Disables all 6 shield entities
Boss_JampanDisableShields:                              ; CODE XREF: Boss_JampanCollapseShieldRadiusState+1A   p  ; was: sub_4A144
                                        ; Boss_JampanCollapseAlternatePatternState+12   p
                move.w  #5,d7
                movea.w #(TwentyThirdEntityType-M68K_RAM),a0
Boss_JampanDisableShieldLoop:                           ; CODE XREF: Boss_JampanDisableShields+12   j  ; was: loc_4A14C
                andi.w  #$7FFF,2(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JampanDisableShieldLoop
                clr.b   (TwentyThirdEntityStatus).w
                rts
; End of function Boss_JampanDisableShields
; Projects the six shield objects from the shared radius and angle fields
Boss_JampanUpdateShieldFormationGeometry:               ; CODE XREF: Boss_JampanShieldCycleDelayState+16   p  ; was: sub_4A160
                                        ; Boss_JampanExpandShieldRadiusState+C   p
                move.w  (SharedScratchLong11).w,d4
                move.w  (SeventhEntityWork4A).w,d5
                move.w  (SeventhEntityWork4C).w,d6
                move.w  (SeventhEntityWork4E).w,d7
                add.w   (SharedScratchLong0).w,d5
                add.w   (SharedScratchLong1).w,d6
                add.w   (SharedScratchLong2).w,d7
                add.w   (SharedScratchLong9+2).w,d5
                add.w   (SharedScratchLong10).w,d6
                add.w   (SharedScratchLong10+2).w,d7
                andi.w  #$1FE,d5
                andi.w  #$1FE,d6
                andi.w  #$1FE,d7
                movea.w #(SeventhEntityType-M68K_RAM),a1
                movea.w #(TwentyEighthEntityType-M68K_RAM),a0
                bsr.w   Boss_JampanProjectPartFromAngles
                movea.w a0,a1
                lea     -$60(a0),a0
                move.w  #4,d0
Boss_JampanProjectNextShieldObject:                     ; CODE XREF: Boss_JampanUpdateShieldFormationGeometry+60   j  ; was: loc_4A1AA
                bsr.w   Boss_JampanProjectPartFromAngles
                move.w  (TwentyEighthEntityAttr).w,$E(a0)
                move.b  (JampanShieldWork20).w,$20(a0)
                movea.w a0,a1
                lea     -$60(a0),a0
                dbf     d0,Boss_JampanProjectNextShieldObject
                cmpi.w  #$52,4(a5)                      ; 'R'
                bcc.s   Boss_JampanClearShieldCollisionField
                move.w  (TwentyThirdEntityAttr).w,d0
                andi.w  #$8000,d0
                bne.s   Boss_JampanSetShieldCollisionField
Boss_JampanClearShieldCollisionField:                   ; CODE XREF: Boss_JampanUpdateShieldFormationGeometry+6A   j  ; was: loc_4A1D6
                clr.b   (TwentyThirdEntityStatus).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanSetShieldCollisionField:                     ; CODE XREF: Boss_JampanUpdateShieldFormationGeometry+74   j  ; was: loc_4A1DC
                move.b  #$40,(TwentyThirdEntityStatus).w  ; '@'
                rts
; End of function Boss_JampanUpdateShieldFormationGeometry
; Type-$23C shield handler: falling motion, bounces, shot burst, and conversion
Boss_JampanShieldMain:                                  ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A1E4
                cmpi.w  #$52,(PrimaryEntityState).w     ; 'R'
                bcc.w   Boss_JampanConvertShieldToProjectile
                cmpi.w  #$180,$14(a5)
                bcs.s   Boss_JampanUpdateShieldMotion
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanUpdateShieldMotion:                          ; CODE XREF: Boss_JampanShieldMain+10   j  ; was: loc_4A1FE
                tst.l   $4C(a5)
                beq.s   Boss_JampanDispatchShieldState
                move.l  $4C(a5),d0
                add.l   d0,$1C(a5)
Boss_JampanDispatchShieldState:                         ; CODE XREF: Boss_JampanShieldMain+1E   j  ; was: loc_4A20C
                move.w  4(a5),d0
                lea     Boss_JampanShieldStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanShieldMain
; ---------------------------------------------------------------------------
Boss_JampanShieldStateHandlers: dc.w    Boss_JampanInitializeFallingShieldState-*  ; DATA XREF: Boss_JampanShieldMain+2C   o  ; was: off_4A218
                dc.w    Boss_JampanUpdateShieldBounceState-*
                dc.w    Boss_JampanPrepareShieldShotBurstState-*
                dc.w    Boss_JampanFireShieldShotBurstState-*
                dc.w    Boss_JampanShieldNoOpState08-*

; Initializes shield with fall speed
Boss_JampanInitializeFallingShieldState:                ; DATA XREF: ROM:Boss_JampanShieldStateHandlers   o  ; was: sub_4A222
                move.l  #$2000,$4C(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanInitializeFallingShieldState
; Handles shield bouncing at Y=$128
Boss_JampanUpdateShieldBounceState:                     ; DATA XREF: ROM:0004A21A   o  ; was: sub_4A236
                cmpi.w  #$128,$14(a5)
                bcs.s   Boss_JampanUpdateShieldBounceReturn
                move.w  #$128,$14(a5)
                subq.w  #1,$48(a5)
                beq.s   Boss_JampanFinishShieldBounces
                move.l  $1C(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                tst.w   $1C(a5)
                bne.s   Boss_JampanUpdateShieldBounceReturn
Boss_JampanFinishShieldBounces:                         ; CODE XREF: Boss_JampanUpdateShieldBounceState+12   j  ; was: loc_4A25C
                clr.l   $1C(a5)
                clr.l   $4C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_JampanUpdateShieldBounceReturn:                    ; CODE XREF: Boss_JampanUpdateShieldBounceState+6   j  ; was: locret_4A26E
                                        ; Boss_JampanUpdateShieldBounceState+24   j
                rts
; End of function Boss_JampanUpdateShieldBounceState
; Waits after the bounces, then prepares a four-shot burst
Boss_JampanPrepareShieldShotBurstState:                 ; DATA XREF: ROM:0004A21C   o  ; was: sub_4A270
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanPrepareShieldShotBurstReturn
                move.w  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$E020E020,$2C(a5)
                move.w  #$FFFA,$1C(a5)
                move.w  #2,$48(a5)
                move.w  #4,$4A(a5)
                addq.w  #2,4(a5)
Boss_JampanPrepareShieldShotBurstReturn:                ; CODE XREF: Boss_JampanPrepareShieldShotBurstState+4   j  ; was: locret_4A2B0
                rts
; End of function Boss_JampanPrepareShieldShotBurstState
; Emits four projectiles, then converts this shield into another projectile
Boss_JampanFireShieldShotBurstState:                    ; DATA XREF: ROM:0004A21E   o  ; was: sub_4A2B2
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanFireShieldShotBurstReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_JampanResetShieldShotTimer
                move.l  #SharedCombatSpriteAnimation03,8(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.l  #$4000,$1C(a0)
                jsr     (Projectile_InitType88).l
                subq.w  #1,$4A(a5)
                beq.s   Boss_JampanConvertShieldToProjectile
Boss_JampanResetShieldShotTimer:                        ; CODE XREF: Boss_JampanFireShieldShotBurstState+C   j  ; was: loc_4A2E8
                move.w  #2,$48(a5)
Boss_JampanFireShieldShotBurstReturn:                   ; CODE XREF: Boss_JampanFireShieldShotBurstState+4   j  ; was: locret_4A2EE
                rts
; ---------------------------------------------------------------------------
Boss_JampanConvertShieldToProjectile:                   ; CODE XREF: Boss_JampanShieldMain+6   j  ; was: loc_4A2F0
                                        ; Boss_JampanFireShieldShotBurstState+34   j
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Boss_JampanFireShieldShotBurstState
Boss_JampanShieldNoOpState08:                           ; DATA XREF: ROM:0004A220   o  ; was: nullsub_102
                rts
; End of function Boss_JampanShieldNoOpState08

; Type-$238 offset-attack object and its derived parameter update
Boss_JampanOffsetAttackObjectMain:                      ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A300
                bsr.s   Boss_JampanDispatchOffsetAttackObjectState
                tst.w   $54(a5)
                beq.s   Boss_JampanOffsetAttackObjectMainReturn
                move.w  $54(a5),d0
                addi.w  #-$20,d0
                move.w  d0,$4C(a5)
Boss_JampanOffsetAttackObjectMainReturn:                ; CODE XREF: Boss_JampanOffsetAttackObjectMain+6   j  ; was: locret_4A314
                rts
; End of function Boss_JampanOffsetAttackObjectMain
; Dispatches the type-$238 object's three state slots
Boss_JampanDispatchOffsetAttackObjectState:             ; CODE XREF: Boss_JampanOffsetAttackObjectMain   p  ; was: sub_4A316
                move.w  4(a5),d0
                lea     Boss_JampanOffsetAttackObjectStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanDispatchOffsetAttackObjectState
; ---------------------------------------------------------------------------
Boss_JampanOffsetAttackObjectStateHandlers: dc.w    Boss_JampanWaitForOffsetAttackTriggerState-*  ; DATA XREF: Boss_JampanDispatchOffsetAttackObjectState+4   o  ; was: off_4A322
                dc.w    Boss_JampanOscillateOffsetAttackParameterState-*
                dc.w    Boss_JampanOffsetAttackObjectNoOpState04-*

; Waits for the controller signal, then seeds the parameter oscillation
Boss_JampanWaitForOffsetAttackTriggerState:             ; DATA XREF: ROM:Boss_JampanOffsetAttackObjectStateHandlers   o  ; was: sub_4A328
                tst.w   $52(a5)
                beq.s   Boss_JampanWaitForOffsetAttackTriggerReturn
                move.w  #8,$50(a5)
                addq.w  #2,4(a5)
                move.w  #4,$56(a5)
Boss_JampanWaitForOffsetAttackTriggerReturn:            ; CODE XREF: Boss_JampanWaitForOffsetAttackTriggerState+4   j  ; was: locret_4A33E
                rts
; End of function Boss_JampanWaitForOffsetAttackTriggerState
; Oscillates field $54 and publishes field $54 minus $20 through field $4C
Boss_JampanOscillateOffsetAttackParameterState:         ; DATA XREF: ROM:0004A324   o  ; was: sub_4A340
                move.w  $56(a5),d0
                add.w   d0,$54(a5)
                tst.w   $54(a5)
                beq.s   Boss_JampanFinishOffsetAttackObjectOscillation
                subq.w  #1,$50(a5)
                bne.s   Boss_JampanOscillateOffsetAttackParameterReturn
                move.w  #$10,$50(a5)
                neg.w   $56(a5)
Boss_JampanOscillateOffsetAttackParameterReturn:        ; CODE XREF: Boss_JampanOscillateOffsetAttackParameterState+12   j  ; was: locret_4A35E
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishOffsetAttackObjectOscillation:         ; CODE XREF: Boss_JampanOscillateOffsetAttackParameterState+C   j  ; was: loc_4A360
                subq.w  #2,4(a5)
                rts
; End of function Boss_JampanOscillateOffsetAttackParameterState
Boss_JampanOffsetAttackObjectNoOpState04:               ; DATA XREF: ROM:0004A326   o  ; was: nullsub_103
                rts
; End of function Boss_JampanOffsetAttackObjectNoOpState04

; Type-$224 object projected radially around the object referenced by field $50
Boss_JampanRadialLinkedObjectMain:                      ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A368
                bsr.s   Boss_JampanDispatchRadialLinkedObjectState
                movea.w $50(a5),a1
                move.b  $20(a1),$20(a5)
                lea     (Math_SineTable).l,a2
                move.w  $4A(a5),d2
                move.w  $48(a5),d3
                move.w  (a2,d2.w),d0
                move.w  -$80(a2,d2.w),d1
                muls.w  d3,d0
                muls.w  d3,d1
                add.l   $10(a1),d0
                add.l   $14(a1),d1
                move.l  d0,$10(a5)
                move.l  d1,$14(a5)
                move.b  $20(a5),d0
                cmp.b   (PrimaryEntityAngle).w,d0
                bhi.s   Boss_JampanClearRadialObjectPriorityFlag
                ori.w   #$8000,$E(a5)
                bra.s   Boss_JampanRadialLinkedObjectMainReturn
; ---------------------------------------------------------------------------
Boss_JampanClearRadialObjectPriorityFlag:               ; CODE XREF: Boss_JampanRadialLinkedObjectMain+3E   j  ; was: loc_4A3B0
                andi.w  #$7FFF,$E(a5)
Boss_JampanRadialLinkedObjectMainReturn:                ; CODE XREF: Boss_JampanRadialLinkedObjectMain+46   j  ; was: locret_4A3B6
                rts
; End of function Boss_JampanRadialLinkedObjectMain
; Dispatches the type-$224 radial object's three state slots
Boss_JampanDispatchRadialLinkedObjectState:             ; CODE XREF: Boss_JampanRadialLinkedObjectMain   p  ; was: sub_4A3B8
                move.w  4(a5),d0
                lea     Boss_JampanRadialLinkedObjectStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanDispatchRadialLinkedObjectState
; ---------------------------------------------------------------------------
Boss_JampanRadialLinkedObjectStateHandlers: dc.w    Boss_JampanWaitForRadialObjectDeploySignalState-*  ; DATA XREF: Boss_JampanDispatchRadialLinkedObjectState+4   o  ; was: off_4A3C4
                dc.w    Boss_JampanExtendRadialLinkedObjectState-*
                dc.w    Boss_JampanRetractRadialLinkedObjectState-*

; Waits for a nonzero deployment signal in field $52
Boss_JampanWaitForRadialObjectDeploySignalState:        ; DATA XREF: ROM:Boss_JampanRadialLinkedObjectStateHandlers   o  ; was: sub_4A3CA
                tst.w   $52(a5)
                beq.w   Boss_JampanWaitForRadialObjectDeploySignalReturn
                addq.w  #2,4(a5)
Boss_JampanWaitForRadialObjectDeploySignalReturn:       ; CODE XREF: Boss_JampanWaitForRadialObjectDeploySignalState+4   j  ; was: locret_4A3D6
                rts
; End of function Boss_JampanWaitForRadialObjectDeploySignalState
; Tracks the player angle and extends the radial distance to $1C
Boss_JampanExtendRadialLinkedObjectState:               ; DATA XREF: ROM:0004A3C6   o  ; was: sub_4A3D8
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d0
                sub.w   $4A(a5),d0
                bpl.s   Boss_JampanCheckExtendedObjectAimDelta
                neg.w   d0
Boss_JampanCheckExtendedObjectAimDelta:                 ; CODE XREF: Boss_JampanExtendRadialLinkedObjectState+C   j  ; was: loc_4A3E8
                cmpi.w  #4,d0
                bls.s   Boss_JampanExtendRadialObjectRadius
                move.w  d2,$4A(a5)
Boss_JampanExtendRadialObjectRadius:                    ; CODE XREF: Boss_JampanExtendRadialLinkedObjectState+14   j  ; was: loc_4A3F2
                cmpi.w  #$1C,$48(a5)
                beq.s   Boss_JampanWaitForRadialObjectRetractSignal
                addq.w  #2,$48(a5)
Boss_JampanWaitForRadialObjectRetractSignal:            ; CODE XREF: Boss_JampanExtendRadialLinkedObjectState+20   j  ; was: loc_4A3FE
                tst.w   $52(a5)
                bne.w   Boss_JampanExtendRadialLinkedObjectReturn
                addq.w  #2,4(a5)
Boss_JampanExtendRadialLinkedObjectReturn:              ; CODE XREF: Boss_JampanExtendRadialLinkedObjectState+2A   j  ; was: locret_4A40A
                rts
; End of function Boss_JampanExtendRadialLinkedObjectState
; Tracks the player angle and retracts the radial distance to zero
Boss_JampanRetractRadialLinkedObjectState:              ; DATA XREF: ROM:0004A3C8   o  ; was: sub_4A40C
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d0
                sub.w   $4A(a5),d0
                bpl.s   Boss_JampanCheckRetractingObjectAimDelta
                neg.w   d0
Boss_JampanCheckRetractingObjectAimDelta:               ; CODE XREF: Boss_JampanRetractRadialLinkedObjectState+C   j  ; was: loc_4A41C
                cmpi.w  #4,d0
                bls.s   Boss_JampanRetractRadialObjectRadius
                move.w  d2,$4A(a5)
Boss_JampanRetractRadialObjectRadius:                   ; CODE XREF: Boss_JampanRetractRadialLinkedObjectState+14   j  ; was: loc_4A426
                subq.w  #2,$48(a5)
                bne.s   Boss_JampanRetractRadialLinkedObjectReturn
                clr.w   4(a5)
Boss_JampanRetractRadialLinkedObjectReturn:             ; CODE XREF: Boss_JampanRetractRadialLinkedObjectState+1E   j  ; was: locret_4A430
                rts
; End of function Boss_JampanRetractRadialLinkedObjectState
; Type-$228 animation object anchored to the object referenced by field $50
Boss_JampanLinkedAnimationObjectMain:                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A432
                bsr.s   Boss_JampanDispatchLinkedAnimationState
                movea.w $50(a5),a1
                move.b  $20(a1),$20(a5)
                move.l  $10(a1),$10(a5)
                move.l  $14(a1),$14(a5)
                move.b  $20(a5),d0
                cmp.b   (PrimaryEntityAngle).w,d0
                bhi.s   Boss_JampanClearAnimationObjectPriorityFlag
                ori.w   #$8000,$E(a5)
                bra.s   Boss_JampanLinkedAnimationObjectMainReturn
; ---------------------------------------------------------------------------
Boss_JampanClearAnimationObjectPriorityFlag:            ; CODE XREF: Boss_JampanLinkedAnimationObjectMain+20   j  ; was: loc_4A45C
                andi.w  #$7FFF,$E(a5)
Boss_JampanLinkedAnimationObjectMainReturn:             ; CODE XREF: Boss_JampanLinkedAnimationObjectMain+28   j  ; was: locret_4A462
                rts
; End of function Boss_JampanLinkedAnimationObjectMain
; Dispatches the type-$228 animation object's four state slots
Boss_JampanDispatchLinkedAnimationState:                ; CODE XREF: Boss_JampanLinkedAnimationObjectMain   p  ; was: sub_4A464
                move.w  4(a5),d0
                lea     Boss_JampanLinkedAnimationStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanDispatchLinkedAnimationState
; ---------------------------------------------------------------------------
Boss_JampanLinkedAnimationStateHandlers:    dc.w    Boss_JampanWaitForLinkedAnimationSignalState-*  ; DATA XREF: Boss_JampanDispatchLinkedAnimationState+4   o  ; was: off_4A470
                dc.w    Boss_JampanActivateLinkedAnimationState-*
                dc.w    Boss_JampanAdvanceLinkedAnimationFramesState-*
                dc.w    Boss_JampanHoldLinkedAnimationHiddenState-*

; Waits for a nonzero animation signal in field $52
Boss_JampanWaitForLinkedAnimationSignalState:           ; DATA XREF: ROM:Boss_JampanLinkedAnimationStateHandlers   o  ; was: sub_4A478
                tst.w   $52(a5)
                beq.s   Boss_JampanWaitForLinkedAnimationSignalReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanWaitForLinkedAnimationSignalReturn:          ; CODE XREF: Boss_JampanWaitForLinkedAnimationSignalState+4   j  ; was: locret_4A488
                rts
; End of function Boss_JampanWaitForLinkedAnimationSignalState
; Delays for $10 frames, makes the object active, and starts frame playback
Boss_JampanActivateLinkedAnimationState:                ; DATA XREF: ROM:0004A472   o  ; was: sub_4A48A
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanActivateLinkedAnimationReturn
                ori.w   #$8000,2(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanActivateLinkedAnimationReturn:               ; CODE XREF: Boss_JampanActivateLinkedAnimationState+4   j  ; was: locret_4A4A0
                rts
; End of function Boss_JampanActivateLinkedAnimationState
; Advances the linked object's six-entry frame sequence every four frames
Boss_JampanAdvanceLinkedAnimationFramesState:           ; DATA XREF: ROM:0004A474   o  ; was: sub_4A4A2
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanAdvanceLinkedAnimationFramesReturn
                move.w  #4,$48(a5)
                move.w  $4A(a5),d0
                move.l  Boss_JampanLinkedAnimationFrameSequence(pc,d0.w),8(a5)
                addq.w  #4,$4A(a5)
                tst.w   $52(a5)
                bpl.s   Boss_JampanCheckLinkedAnimationFrameLimit
                cmpi.w  #$FFFE,$52(a5)
                bne.s   Boss_JampanCheckShortLinkedAnimationSequence
                cmpi.w  #$C,$4A(a5)
                beq.s   Boss_JampanResetLinkedAnimationAfterSignal
                bra.s   Boss_JampanCheckLinkedAnimationFrameLimit
; ---------------------------------------------------------------------------
Boss_JampanCheckShortLinkedAnimationSequence:           ; CODE XREF: Boss_JampanAdvanceLinkedAnimationFramesState+26   j  ; was: loc_4A4D4
                cmpi.w  #8,$4A(a5)
                bne.s   Boss_JampanCheckLinkedAnimationFrameLimit
Boss_JampanResetLinkedAnimationAfterSignal:             ; CODE XREF: Boss_JampanAdvanceLinkedAnimationFramesState+2E   j  ; was: loc_4A4DC
                clr.w   $52(a5)
                clr.w   4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanCheckLinkedAnimationFrameLimit:              ; CODE XREF: Boss_JampanAdvanceLinkedAnimationFramesState+1E   j  ; was: loc_4A4E6
                                        ; Boss_JampanAdvanceLinkedAnimationFramesState+30   j
                cmpi.w  #$18,$4A(a5)
                bne.s   Boss_JampanAdvanceLinkedAnimationFramesReturn
                addq.w  #2,4(a5)
Boss_JampanAdvanceLinkedAnimationFramesReturn:          ; CODE XREF: Boss_JampanAdvanceLinkedAnimationFramesState+4   j  ; was: locret_4A4F2
                                        ; Boss_JampanAdvanceLinkedAnimationFramesState+4A   j
                rts
; End of function Boss_JampanAdvanceLinkedAnimationFramesState
; ---------------------------------------------------------------------------
Boss_JampanLinkedAnimationFrameSequence:    dc.l    Boss_JampanLinkedAnimationMappingA  ; DATA XREF: Boss_JampanAdvanceLinkedAnimationFramesState+10   r  ; was: off_4A4F4
                dc.l    Boss_JampanLinkedAnimationMappingB
                dc.l    Boss_JampanLinkedAnimationMappingC
                dc.l    Boss_JampanLinkedAnimationMappingB
                dc.l    Boss_JampanLinkedAnimationMappingA
                dc.l    Boss_JampanLinkedPartMappingB

; Hides the linked object and resolves the signed animation signal
Boss_JampanHoldLinkedAnimationHiddenState:              ; DATA XREF: ROM:0004A476   o  ; was: sub_4A50C
                subq.w  #1,$48(a5)
                beq.s   Boss_JampanHoldLinkedAnimationHiddenReturn
                clr.w   $4A(a5)
                andi.w  #$7FFF,2(a5)
                tst.w   $52(a5)
                bmi.s   Boss_JampanRestartLinkedAnimationFrameCycle
                subq.w  #1,$52(a5)
                beq.s   Boss_JampanFinishLinkedAnimationSignal
Boss_JampanRestartLinkedAnimationFrameCycle:            ; CODE XREF: Boss_JampanHoldLinkedAnimationHiddenState+14   j  ; was: loc_4A528
                move.w  #4,$48(a5)
                subq.w  #4,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishLinkedAnimationSignal:                 ; CODE XREF: Boss_JampanHoldLinkedAnimationHiddenState+1A   j  ; was: loc_4A534
                clr.w   4(a5)
Boss_JampanHoldLinkedAnimationHiddenReturn:             ; CODE XREF: Boss_JampanHoldLinkedAnimationHiddenState+4   j  ; was: locret_4A538
                rts
; End of function Boss_JampanHoldLinkedAnimationHiddenState
; Type-$22C controller for the angular accumulators of 13 linked parts
Boss_JampanOrbitGroupControllerMain:                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A53A
                move.w  4(a5),d0
                lea     Boss_JampanOrbitGroupStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanOrbitGroupControllerMain
; ---------------------------------------------------------------------------
Boss_JampanOrbitGroupStateHandlers: dc.w    Boss_JampanInitializeOrbitGroupAnglesState-*  ; DATA XREF: Boss_JampanOrbitGroupControllerMain+4   o  ; was: off_4A546
                dc.w    Boss_JampanWaitForOrbitGroupRotationSignalState-*
                dc.w    Boss_JampanRotateOrbitGroupForwardState-*
                dc.w    Boss_JampanRotateOrbitGroupBackwardState-*

; Initializes the 13 angular accumulators to $20.0000
Boss_JampanInitializeOrbitGroupAnglesState:             ; DATA XREF: ROM:Boss_JampanOrbitGroupStateHandlers   o  ; was: sub_4A54E
                move.w  #$C,d7
                movea.w #(TenthEntityType-M68K_RAM),a0
Boss_JampanInitializeOrbitGroupAngleLoop:               ; CODE XREF: Boss_JampanInitializeOrbitGroupAnglesState+14   j  ; was: loc_4A556
                move.l  #$200000,$54(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JampanInitializeOrbitGroupAngleLoop
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanInitializeOrbitGroupAnglesState
; Waits for a nonzero group-rotation signal in field $52
Boss_JampanWaitForOrbitGroupRotationSignalState:        ; DATA XREF: ROM:0004A548   o  ; was: sub_4A56C
                tst.w   $52(a5)
                beq.s   Boss_JampanWaitForOrbitGroupRotationSignalReturn
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_JampanWaitForOrbitGroupRotationSignalReturn:       ; CODE XREF: Boss_JampanWaitForOrbitGroupRotationSignalState+4   j  ; was: locret_4A57C
                rts
; End of function Boss_JampanWaitForOrbitGroupRotationSignalState
; Applies the forward angular-velocity table for $20 frames
Boss_JampanRotateOrbitGroupForwardState:                ; DATA XREF: ROM:0004A54A   o  ; was: sub_4A57E
                move.w  #$C,d7
                movea.w #(TenthEntityType-M68K_RAM),a0
                clr.w   d6
Boss_JampanRotateOrbitGroupForwardLoop:                 ; CODE XREF: Boss_JampanRotateOrbitGroupForwardState+28   j  ; was: loc_4A588
                move.l  Boss_JampanForwardAngularVelocityTable(pc,d6.w),d0
                add.l   d0,$54(a0)
                add.l   d0,$54(a0)
                move.w  $54(a0),$4C(a0)
                andi.w  #$1FF,$4C(a0)
                addq.w  #4,d6
                lea     $60(a0),a0
                dbf     d7,Boss_JampanRotateOrbitGroupForwardLoop
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanRotateOrbitGroupForwardReturn
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_JampanRotateOrbitGroupForwardReturn:               ; CODE XREF: Boss_JampanRotateOrbitGroupForwardState+30   j  ; was: locret_4A5BA
                rts
; End of function Boss_JampanRotateOrbitGroupForwardState
; ---------------------------------------------------------------------------
Boss_JampanForwardAngularVelocityTable: dc.l    $FFFFF800, $FFFFF000, $FFFFE000, $FFFFE000, $FFFFE000, $FFFFF000, $FFFFF800  ; was: dword_4A5BC
                                        ; DATA XREF: Boss_JampanRotateOrbitGroupForwardState:Boss_JampanRotateOrbitGroupForwardLoop   r
                dc.l    $4000, $8000, $C000, $C000, $8000, $4000
