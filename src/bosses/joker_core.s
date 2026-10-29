Boss_JokerMain:                                         ; was: sub_3B29E
                tst.w   4(a5)
                beq.w   Boss_JokerDispatchState
                tst.w   8(a5)
                beq.s   Boss_JokerDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_JokerUpdatePaletteAndScreenX
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_JokerUpdatePaletteAndScreenX
                tst.w   (BossHealth).w
                beq.w   Boss_JokerBeginDefeatFall
Boss_JokerUpdatePaletteAndScreenX:                      ; was: loc_3B2C4
                                        ; Boss_JokerMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
Boss_JokerDispatchState:                                ; was: loc_3B2D6
                                        ; Boss_JokerMain+C   j
                move.w  4(a5),d0
                movea.w Boss_JokerStateOffsets(pc,d0.w),a0
                adda.l  #Boss_JokerInit,a0
                jmp     (a0)
; End of function Boss_JokerMain
; ---------------------------------------------------------------------------
Boss_JokerStateOffsets: dc.w    Boss_JokerInit-Boss_JokerInit  ; was: off_3B2E6
                dc.w    Boss_JokerSetup-Boss_JokerInit
                dc.w    Boss_JokerBeginInterruptWaitState-Boss_JokerInit
                dc.w    Boss_JokerDivePrep-Boss_JokerInit
                dc.w    Boss_JokerDiveMotionState-Boss_JokerInit
                dc.w    Boss_JokerDiveDescentState-Boss_JokerInit
                dc.w    Boss_JokerStretchState-Boss_JokerInit
                dc.w    Boss_JokerJumpPreparationState-Boss_JokerInit
                dc.w    Boss_JokerJumpAscentState-Boss_JokerInit
                dc.w    Boss_JokerBodyHeightCompressionState-Boss_JokerInit
                dc.w    Boss_JokerBodyHeightRecoveryState-Boss_JokerInit
                dc.w    Boss_JokerBounceMotionState-Boss_JokerInit
                dc.w    Boss_JokerPhaseGateDelayState-Boss_JokerInit
                dc.w    Boss_JokerWaitForPlayerSequenceState-Boss_JokerInit
                dc.w    Boss_JokerPhaseGateCompletionDelayState-Boss_JokerInit
                dc.w    Boss_JokerDefeatFallDelayState-Boss_JokerInit
                dc.w    Boss_JokerFadeOutState-Boss_JokerInit
                dc.w    Boss_JokerFadeInState-Boss_JokerInit
                dc.w    Boss_JokerCleanup-Boss_JokerInit
                dc.w    Boss_JokerInterruptWaitState-Boss_JokerInit

; Initializes Joker boss clearing sprites and setting scroll position
Boss_JokerInit:                                         ; was: sub_3B30E
                                        ; ROM:Boss_JokerStateOffsets   o
                addq.w  #2,4(a5)
                clr.w   8(a5)
                move.w  (PrimaryCameraXPosition).w,$48(a5)
                move.w  #4,$4A(a5)
                move.w  #$15C,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
Boss_JokerInitializationReturn:                         ; was: locret_3B32E
                rts
; End of function Boss_JokerInit
; Stages tilemap rendering, then initializes Joker's metasprite and objects
Boss_JokerSetup:                                        ; was: sub_3B330
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_JokerInitializationReturn
                subq.w  #1,$4A(a5)
                bmi.s   Boss_JokerInitializeMetasprite
                addi.w  #8,$48(a5)
                move.w  $48(a5),d0
                addi.w  #$158,d0
                move.w  (PrimaryCameraYPosition).w,d1
                jmp     Tilemap_QueuePrimaryPlaneColumn
; ---------------------------------------------------------------------------
Boss_JokerInitializeMetasprite:                         ; was: loc_3B354
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$12,d7
                movea.l #Boss_JokerMetaspriteDescriptors,a0
                movea.l #Boss_JokerPartRadii,a1
                movea.l #Boss_JokerPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                movea.w #(TwentiethEntityType-M68K_RAM),a0
                moveq   #0,d0
                moveq   #3,d7
Boss_JokerInitializeAuxiliaryObjectTypes:               ; was: loc_3B382
                move.w  #$10,(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JokerInitializeAuxiliaryObjectTypes
                move.w  #$15C,(a5)
                moveq   #0,d0
                bset    d0,2(a5)
                bset    d0,$362(a5)
                bset    d0,$6C2(a5)
                movea.l #Boss_JokerObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                lea     Boss_JokerIndexedRowTransferDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #7,d0
                moveq   #$11,d7
Boss_JokerEnableLinkedPartFlag7:                        ; was: loc_3B3C0
                bset    d0,3(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JokerEnableLinkedPartFlag7
                move.w  #2,$35C(a5)
                move.w  #$238,$10(a5)
                move.w  #$40,$1DC(a5)                   ; '@'
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.w  #$E,(RasterLayoutOffset).w
                move.b  #2,(PlaneBScrollModeFlags).w
                bra.w   Boss_JokerBeginDiveState
; End of function Boss_JokerSetup
; ---------------------------------------------------------------------------
Boss_JokerIndexedRowTransferDescriptor: dc.b    $61, 0, $20, 0, 3, 2, 0, $40, $41  ; was: byte_3B3F8
                dc.b    0, $45, $44, $42, $43, $48, $3C, $46, $47

; Starts the phase gate before the player/UI sequence
Boss_JokerBeginPhaseGate:                               ; was: sub_3B40A
                move.w  #$18,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; End of function Boss_JokerBeginPhaseGate
; Counts down before requesting player/UI sequence five
Boss_JokerPhaseGateDelayState:                          ; was: sub_3B420
                subq.w  #1,$11C(a5)
                bpl.w   Boss_JokerUpdatePhaseGatePose
                addq.w  #2,4(a5)
                moveq   #5,d0
                jsr     (BossMessage_Start).l
; End of function Boss_JokerPhaseGateDelayState
; Waits for the player/UI sequence to finish
Boss_JokerWaitForPlayerSequenceState:                   ; was: sub_3B434
                tst.w   (MessageSequenceState).w
                bne.w   Boss_JokerUpdatePhaseGatePose
                addq.w  #2,4(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; Counts down after the player/UI sequence before returning to battle
Boss_JokerPhaseGateCompletionDelayState:                ; was: loc_3B446
                subq.w  #1,$11C(a5)
                bpl.s   Boss_JokerUpdatePhaseGatePose
                clr.b   (BossColorEffectFlags).w
                clr.w   $35C(a5)
                subi.w  #$60,(CameraXLowerBound).w      ; '`'
                addi.w  #$40,(CameraXUpperBound).w      ; '@'
                bra.w   Boss_JokerSelectNextState
; ---------------------------------------------------------------------------
Boss_JokerUpdatePhaseGatePose:                          ; was: loc_3B464
                                        ; Boss_JokerWaitForPlayerSequenceState+4   j
                lea     Boss_JokerPhaseGatePoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                move.w  $58(a5),d7
                cmpi.w  #$10,d7
                beq.s   Boss_JokerIncreasePhaseGateBodyHeight
                cmpi.w  #4,d7
                bne.s   Boss_JokerDecreasePhaseGateBodyHeight
Boss_JokerIncreasePhaseGateBodyHeight:                  ; was: loc_3B47E
                cmpi.w  #$56,$1DC(a5)                   ; 'V'
                bpl.s   Boss_JokerCheckPhaseGateFacingToggle
                addq.w  #2,$1DC(a5)
                bra.s   Boss_JokerCheckPhaseGateFacingToggle
; ---------------------------------------------------------------------------
Boss_JokerDecreasePhaseGateBodyHeight:                  ; was: loc_3B48C
                cmpi.w  #$32,$1DC(a5)                   ; '2'
                bmi.s   Boss_JokerCheckPhaseGateFacingToggle
                subq.w  #1,$1DC(a5)
Boss_JokerCheckPhaseGateFacingToggle:                   ; was: loc_3B498
                                        ; Boss_JokerUpdatePhaseGatePose+56   j
                tst.w   $3BC(a5)
                beq.s   Boss_JokerRenderPhaseGatePose
                cmpi.w  #8,$58(a5)
                beq.s   Boss_JokerTogglePhaseGateFacing
                cmpi.w  #$14,$58(a5)
                bne.s   Boss_JokerRenderPhaseGatePose
Boss_JokerTogglePhaseGateFacing:                        ; was: loc_3B4AE
                eori.w  #$100,$54(a5)
                move.w  $370(a5),$6D0(a5)
Boss_JokerRenderPhaseGatePose:                          ; was: loc_3B4BA
                                        ; Boss_JokerUpdatePhaseGatePose+78   j
                move.w  #$CCE0,$48(a5)
                move.w  #$CCE0,$4A(a5)
                move.w  #$144,$6D4(a5)
                bsr.w   Boss_JokerRenderBody
                move.w  #$144,$374(a5)
                rts
; End of function Boss_JokerWaitForPlayerSequenceState
; Initializes Joker's health-zero falling sequence
Boss_JokerBeginDefeatFall:                              ; was: sub_3B4D8
                move.w  #4,(StageSpawnCountdown).w
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,(StageTimerPauseFlag).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #$1E,4(a5)
                clr.w   $29E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $54(a5)
                move.w  #$40,$1DC(a5)                   ; '@'
                clr.l   $18(a5)
                move.l  #$FFFEE000,$1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$80,$11C(a5)
                clr.w   $A(a5)
                bra.s   Boss_JokerDefeatFallDelayState
; End of function Boss_JokerBeginDefeatFall
; Increases the fade counter, then replaces the boss objects with player spawn
Boss_JokerFadeOutState:                                 ; was: sub_3B52E
                bsr.w   Boss_JokerApplyFadeCounter
                addq.w  #1,$A(a5)
                cmpi.w  #$20,$A(a5)                     ; ' '
                bmi.s   Boss_JokerUpdateDefeatFall
                addq.w  #2,4(a5)
                clr.w   2(a5)
                clr.w   8(a5)
                move.w  #$15C,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #4,(PlaneAScrollModeFlags).w
                jsr     (TransitionEffect_SpawnAtOwner).l
                addi.w  #$10,$14(a0)
                rts
; End of function Boss_JokerFadeOutState
; Delays the fade-out state while updating the defeat fall
Boss_JokerDefeatFallDelayState:                         ; was: sub_3B56A
                subq.w  #1,$11C(a5)
                bpl.s   Boss_JokerUpdateDefeatPaletteFade
                addq.w  #2,4(a5)
Boss_JokerUpdateDefeatPaletteFade:                      ; was: loc_3B574
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
Boss_JokerUpdateDefeatFall:                             ; was: loc_3B57A
                bsr.w   Boss_JokerSpawnDefeatEffect
                move.w  #4,(PlaneAShakeLevel).w
                addi.l  #$3000,$1C(a5)
                bpl.s   Boss_JokerUpdateDefeatDescent
                cmpi.w  #$48,$1DC(a5)                   ; 'H'
                bpl.s   Boss_JokerAnimateDefeatFall
                addi.l  #$18000,$1DC(a5)
                bra.s   Boss_JokerAnimateDefeatFall
; End of function Boss_JokerDefeatFallDelayState
; Adjusts body height and clamps the health-zero fall to Y $120
Boss_JokerUpdateDefeatDescent:                          ; was: sub_3B5A0
                cmpi.w  #$34,$1DC(a5)                   ; '4'
                bmi.s   Boss_JokerClampDefeatFallY
                subi.l  #$18000,$1DC(a5)
Boss_JokerClampDefeatFallY:                             ; was: loc_3B5B0
                cmpi.w  #$120,$14(a5)
                bmi.s   Boss_JokerAnimateDefeatFall
                move.w  #$120,$14(a5)
                move.l  #$FFFCC000,$1C(a5)
Boss_JokerAnimateDefeatFall:                            ; was: loc_3B5C6
                                        ; Boss_JokerDefeatFallDelayState+34   j
                lea     Boss_JokerDefeatFallPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; End of function Boss_JokerUpdateDefeatDescent
; Decreases the fade counter back to zero
Boss_JokerFadeInState:                                  ; was: sub_3B5D4
                subq.w  #2,$A(a5)
                bne.s   Boss_JokerApplyFadeInLevel
                addq.w  #2,4(a5)
                move.w  #$70,$11C(a5)                   ; 'p'
Boss_JokerApplyFadeInLevel:                             ; was: loc_3B5E4
                bra.w   Boss_JokerApplyFadeCounter
; End of function Boss_JokerFadeInState
; Cleans up Joker boss removing entity and clearing flags
Boss_JokerCleanup:                                      ; was: sub_3B5E8
                subq.w  #1,$11C(a5)
                bpl.s   Boss_JokerCleanupReturn
                bset    #4,2(a5)
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                clr.b   (VDPReg11Shadow+1).w
Boss_JokerCleanupReturn:                                ; was: locret_3B600
                rts
; End of function Boss_JokerCleanup
; Spawns a randomized debris or type-$160 effect during the defeat fall
Boss_JokerSpawnDefeatEffect:                            ; was: sub_3B602
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_JokerSpawnDefeatEffectReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                bne.s   Boss_JokerInitializeType160DefeatEffect
                jsr     (Effect_InitDebrisSprite).l
                bra.w   Boss_JokerPositionDefeatEffect
; ---------------------------------------------------------------------------
Boss_JokerInitializeType160DefeatEffect:                ; was: loc_3B624
                jsr     (Sprite_InitType160).l
                bset    #7,3(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  #$FFFE,$1C(a0)
                btst    #0,(RandomNumberState).w
                beq.s   Boss_JokerPositionDefeatEffect
                move.l  #Effect_SpriteAnimation06,8(a0)
                clr.w   $1C(a0)
Boss_JokerPositionDefeatEffect:                         ; was: loc_3B65E
                                        ; Boss_JokerSpawnDefeatEffect+4E   j
                move.b  #0,$20(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d0                         ; ' '
                subi.w  #$12,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_JokerSpawnDefeatEffectReturn:                      ; was: locret_3B68C
                rts
; End of function Boss_JokerSpawnDefeatEffect
; Sets graphics fade level based on counter value
Boss_JokerApplyFadeCounter:                             ; was: sub_3B68E
                                        ; Boss_JokerFadeInState:Boss_JokerApplyFadeInLevel   j
                move.w  $A(a5),d0
                asr.w   #1,d0
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; End of function Boss_JokerApplyFadeCounter
; Selects the next state from shared progress, player distance, and RNG
Boss_JokerSelectNextState:                              ; was: sub_3B69A
                                        ; Boss_JokerBeginInterruptWaitState+12   j
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  #$C980,$4A(a5)
                move.w  #$144,$374(a5)
                clr.l   $18(a5)
                move.w  #$40,$1DC(a5)                   ; '@'
                tst.w   (BossCombatCounter).w
                bmi.s   Boss_JokerBeginInterruptWaitState
                beq.s   Boss_JokerBeginInterruptWaitState
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$6A,d0                         ; 'j'
                bpl.s   Boss_JokerSelectDistantPlayerState
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.w   Boss_JokerBeginDiveState
                bra.w   Boss_JokerBeginJumpSequence
; ---------------------------------------------------------------------------
Boss_JokerSelectDistantPlayerState:                     ; was: loc_3B6E8
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                beq.w   Boss_JokerBeginJumpSequence
                bra.w   Boss_JokerBeginDiveState
; End of function Boss_JokerSelectNextState
; Starts the interrupt-wait pose state
Boss_JokerBeginInterruptWaitState:                      ; was: sub_3B6F8
                                        ; Boss_JokerSelectNextState+30   j
                move.w  #$26,4(a5)                      ; '&'
                move.w  #$30,$11C(a5)                   ; '0'
; Waits for shared flag bit zero before selecting the next state
Boss_JokerInterruptWaitState:                           ; was: loc_3B704
                bclr    #0,(BossCounterMaxFlag).w
                bne.w   Boss_JokerSelectNextState
                addi.w  #2,(BossCombatCounter).w
                lea     Boss_JokerInterruptWaitPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; End of function Boss_JokerBeginInterruptWaitState
; Initializes the dive preparation state
Boss_JokerBeginDiveState:                               ; was: sub_3B722
                                        ; Boss_JokerSelectNextState+46   j
                move.w  #$16,$26(a5)
                move.w  #6,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  #$C980,$4A(a5)
                move.w  #$144,$374(a5)
; End of function Boss_JokerBeginDiveState
; Joker boss dive preparation with sound and velocity initialization
Boss_JokerDivePrep:                                     ; was: sub_3B748
                tst.w   $58(a5)
                bmi.s   Boss_JokerInitializeDiveMotion
                lea     Boss_JokerDiveAndJumpPreparationPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerInitializeDiveMotion:                         ; was: loc_3B75C
                move.b  #$44,d0                         ; 'D'
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFFEC000,$23C(a5)
                move.l  #$FFFB0000,$1C(a5)
                move.w  #2,(PlaneAShakeLevel).w
                move.b  #$44,d0                         ; 'D'
                jsr     (Sound_QueueSFXRequest).l
                tst.w   $35C(a5)
                bne.s   Boss_JokerSelectDiveHorizontalMotion
                subi.w  #$C,(BossCombatCounter).w
Boss_JokerSelectDiveHorizontalMotion:                   ; was: loc_3B7A4
                tst.w   $35C(a5)
                beq.s   Boss_JokerSetPlayerDirectedDiveMotion
                move.l  #$FFFEC000,$18(a5)
                bra.s   Boss_JokerDiveMotionState
; ---------------------------------------------------------------------------
Boss_JokerSetPlayerDirectedDiveMotion:                  ; was: loc_3B7B4
                jsr     (Physics_GetPlayerDelta).l
                move.l  #$10000,d0
                move.w  (RandomNumberState).w,d0
                tst.w   d1
                bpl.s   Boss_JokerStoreDiveHorizontalVelocity
                neg.l   d0
Boss_JokerStoreDiveHorizontalVelocity:                  ; was: loc_3B7CA
                move.l  d0,$18(a5)
; Updates accelerated dive motion until vertical velocity becomes nonnegative
Boss_JokerDiveMotionState:                              ; was: loc_3B7CE
                bsr.s   Boss_JokerUpdateDiveBodyMotion
                bpl.s   Boss_JokerAdvanceToDiveDescentState
                lea     Boss_JokerDiveMotionPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; End of function Boss_JokerDivePrep
; Applies acceleration to body height and vertical velocity
Boss_JokerUpdateDiveBodyMotion:                         ; was: sub_3B7E0
                                        ; Boss_JokerDiveDescentState   p
                addi.l  #$A00,$23C(a5)
                move.l  $23C(a5),d0
                add.l   d0,$1DC(a5)
                addi.l  #$2000,$1C(a5)
                rts
; End of function Boss_JokerUpdateDiveBodyMotion
; Advances from rising dive motion to the descent state
Boss_JokerAdvanceToDiveDescentState:                    ; was: sub_3B7FA
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; End of function Boss_JokerAdvanceToDiveDescentState
; Continues accelerated dive descent until the linked Y boundary
Boss_JokerDiveDescentState:                             ; was: sub_3B808
                bsr.s   Boss_JokerUpdateDiveBodyMotion
                cmpi.w  #$144,$374(a5)
                bpl.s   Boss_JokerBeginStretchState
                lea     Boss_JokerDiveDescentAndBouncePoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerBeginStretchState:                            ; was: loc_3B820
                                        ; Boss_JokerBounceMotionState+18   j
                move.w  #$C,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$C980,$4A(a5)
                move.w  #$144,$374(a5)
                clr.l   $1C(a5)
                move.b  #$53,d0                         ; 'S'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_JokerSpawnDescendingShotEmitter
; End of function Boss_JokerDiveDescentState
; Joker boss stretch state adjusting hitbox size dynamically
Boss_JokerStretchState:                                 ; was: sub_3B84E
                move.w  $58(a5),d0
                bmi.s   Boss_JokerSelectPostStretchState
                cmpi.w  #$C,d0
                bmi.s   Boss_JokerContractStretchBodyHeight
                cmpi.w  #$40,$1DC(a5)                   ; '@'
                bpl.s   Boss_JokerUpdateStretchPose
                addq.w  #1,$1DC(a5)
                bra.s   Boss_JokerUpdateStretchPose
; ---------------------------------------------------------------------------
Boss_JokerContractStretchBodyHeight:                    ; was: loc_3B868
                cmpi.w  #$30,$1DC(a5)                   ; '0'
                bmi.s   Boss_JokerUpdateStretchPose
                subq.w  #2,$1DC(a5)
Boss_JokerUpdateStretchPose:                            ; was: loc_3B874
                                        ; Boss_JokerStretchState+18   j
                bsr.w   Boss_JokerSlowHorizontalVelocity
                lea     Boss_JokerStretchPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerSelectPostStretchState:                       ; was: loc_3B886
                tst.w   $35C(a5)
                beq.s   Boss_JokerReturnToNextStateSelection
                cmpi.w  #$190,$10(a5)
                bpl.w   Boss_JokerBeginDiveState
                bra.w   Boss_JokerBeginPhaseGate
; ---------------------------------------------------------------------------
Boss_JokerReturnToNextStateSelection:                   ; was: loc_3B89A
                bra.w   Boss_JokerSelectNextState
; End of function Boss_JokerStretchState
; Starts the jump preparation state
Boss_JokerBeginJumpSequence:                            ; was: sub_3B89E
                                        ; Boss_JokerSelectNextState+56   j
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  #$C980,$4A(a5)
                move.w  #$144,$374(a5)
; End of function Boss_JokerBeginJumpSequence
; Advances the jump preparation pose before launching upward
Boss_JokerJumpPreparationState:                         ; was: sub_3B8BE
                tst.w   $58(a5)
                bmi.s   Boss_JokerInitializeJumpAscent
                subi.l  #$8000,$1DC(a5)
                lea     Boss_JokerDiveAndJumpPreparationPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerInitializeJumpAscent:                         ; was: loc_3B8DA
                move.b  #$44,d0                         ; 'D'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$56,$26(a5)                    ; 'V'
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFF80000,$1C(a5)
                subi.w  #$3E,(BossCombatCounter).w      ; '>'
                move.w  #2,(PlaneAShakeLevel).w
                move.b  #$44,d0                         ; 'D'
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_JokerJumpPreparationState
; Applies upward jump motion until the derived body edge reaches Y $C8
Boss_JokerJumpAscentState:                              ; was: sub_3B91A
                addi.l  #$2000,$1C(a5)
                addq.w  #2,$1DC(a5)
                move.w  $1DC(a5),d0
                subi.w  #$40,d0                         ; '@'
                asr.w   #1,d0
                add.w   $14(a5),d0
                cmpi.w  #$C8,d0
                bmi.s   Boss_JokerBeginBodyHeightCompression
                lea     Boss_JokerJumpAscentPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerBeginBodyHeightCompression:                   ; was: loc_3B948
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$FFFE0000,$23C(a5)
                clr.l   $1C(a5)
                move.w  #5,(PlaneAShakeLevel).w
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$16,$26(a5)
; Compresses body height with a decaying negative accumulator
Boss_JokerBodyHeightCompressionState:                   ; was: loc_3B978
                addi.l  #$1000,$23C(a5)
                bpl.s   Boss_JokerUpdateBodyHeightCompressionPose
                move.l  $23C(a5),d0
                add.l   d0,$1DC(a5)
Boss_JokerUpdateBodyHeightCompressionPose:              ; was: loc_3B98A
                bsr.w   Boss_JokerDeriveYFromBodyHeight
                tst.w   $58(a5)
                bmi.s   Boss_JokerBeginBodyHeightRecovery
                lea     Boss_JokerBodyHeightCompressionPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; ---------------------------------------------------------------------------
Boss_JokerBeginBodyHeightRecovery:                      ; was: loc_3B9A2
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $23C(a5)
; Restores body height with an increasing positive accumulator
Boss_JokerBodyHeightRecoveryState:                      ; was: loc_3B9B4
                bsr.s   Boss_JokerUpdateBodyHeightAcceleration
                cmpi.w  #$40,$1DC(a5)                   ; '@'
                bpl.s   Boss_JokerAdvanceToBounceMotionState
                bsr.w   Boss_JokerDeriveYFromBodyHeight
                lea     Boss_JokerBodyHeightRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   Boss_JokerRenderBody
; End of function Boss_JokerJumpAscentState
; Adds an increasing accumulator to fixed-point body height
Boss_JokerUpdateBodyHeightAcceleration:                 ; was: sub_3B9D0
                                        ; Boss_JokerBounceMotionState+8   p
                addi.l  #$180,$23C(a5)
                move.l  $23C(a5),d0
                add.l   d0,$1DC(a5)
                rts
; End of function Boss_JokerUpdateBodyHeightAcceleration
; Advances from body-height recovery to bounce motion
Boss_JokerAdvanceToBounceMotionState:                   ; was: sub_3B9E2
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; End of function Boss_JokerAdvanceToBounceMotionState
; Continues body-height and vertical acceleration before stretch
Boss_JokerBounceMotionState:                            ; was: sub_3B9F0
                addi.l  #$280,$23C(a5)
                bsr.s   Boss_JokerUpdateBodyHeightAcceleration
                addi.l  #$2000,$1C(a5)
                cmpi.w  #$140,$374(a5)
                bpl.w   Boss_JokerBeginStretchState
                lea     Boss_JokerDiveDescentAndBouncePoses(pc),a1
                nop
                bsr.w   Boss_JokerUpdatePose
                bra.w   *+4
; End of function Boss_JokerBounceMotionState
