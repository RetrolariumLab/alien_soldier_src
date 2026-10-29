; Stage 3 type-$190 boss controller with eight orbiting parts
Boss_Stage3OrbitingFormationMain:                       ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_33F30
                bsr.w   Boss_Stage3OrbitingFormationCheckDefeat
                bsr.w   Boss_Stage3OrbitingFormationDispatchState
                bsr.s   Boss_Stage3OrbitingFormationUpdateSpinSound
                cmpi.w  #2,4(a5)
                bls.w   Boss_Stage3OrbitingFormationReturn
                bsr.w   Boss_Stage3OrbitingFormationUpdateMotion
                bsr.w   Boss_Stage3OrbitingFormationUpdateParts
                bsr.w   Boss_Stage3OrbitingFormationUpdateVerticalVelocity
                bsr.w   Boss_Stage3OrbitingFormationHandleHitFlash
                rts
; End of function Boss_Stage3OrbitingFormationMain
; Plays the rotation sound at an interval selected by the current spin rate
Boss_Stage3OrbitingFormationUpdateSpinSound:            ; CODE XREF: Boss_Stage3OrbitingFormationMain+8   p  ; was: sub_33F56
                tst.w   $50(a5)
                beq.s   Boss_Stage3OrbitingFormationSpinSoundReturn
                subq.w  #1,(SharedScratchLong0).w
                bpl.s   Boss_Stage3OrbitingFormationSpinSoundReturn
                move.w  $50(a5),d0
                add.w   d0,d0
                move.w  Boss_Stage3OrbitingFormationSpinSoundDelays(pc,d0.w),(SharedScratchLong0).w
                move.b  #$54,d0                         ; 'T'
                jsr     (Sound_QueueSFXRequest).l
Boss_Stage3OrbitingFormationSpinSoundReturn:            ; CODE XREF: Boss_Stage3OrbitingFormationUpdateSpinSound+4   j  ; was: locret_33F78
                                        ; Boss_Stage3OrbitingFormationUpdateSpinSound+A   j
                rts
; End of function Boss_Stage3OrbitingFormationUpdateSpinSound
; ---------------------------------------------------------------------------
Boss_Stage3OrbitingFormationSpinSoundDelays:    dc.w    0, $28, $20, $2C, $18  ; was: word_33F7A
                                        ; DATA XREF: Boss_Stage3OrbitingFormationUpdateSpinSound+12   r

; Releases all eight parts and creates explosion rings when boss health reaches zero
Boss_Stage3OrbitingFormationCheckDefeat:                ; CODE XREF: Boss_Stage3OrbitingFormationMain   p  ; was: sub_33F84
                cmpi.w  #2,4(a5)
                bls.w   Boss_Stage3OrbitingFormationReturn
                btst    #1,(BossColorEffectFlags).w
                bne.w   Boss_Stage3OrbitingFormationReturn
                tst.w   (BossHealth).w
                bne.w   Boss_Stage3OrbitingFormationReturn
                move.w  #2,4(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #7,d7
                lea     (SecondaryEntityType).w,a0
Boss_Stage3OrbitingFormationReleaseNextPart:            ; CODE XREF: Boss_Stage3OrbitingFormationCheckDefeat+6C   j  ; was: loc_33FB6
                move.w  SecondaryEntityWork4C-SecondaryEntityType(a0),d2
                add.w   $4C(a5),d2
                add.w   d2,d2
                lea     (Math_SineTable).l,a1
                move.w  (a1,d2.w),d0
                move.w  -$80(a1,d2.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #4,d0
                asl.l   #4,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Sprite_InitType160).l
                adda.w  #$60,a0                         ; '`'
                dbf     d7,Boss_Stage3OrbitingFormationReleaseNextPart
                move.w  #3,d1
                move.w  #0,d2
                jsr     (Effect_SpawnEightWayExplosionParticles).l
                move.w  #4,d1
                move.w  #$20,d2                         ; ' '
                jsr     (Effect_SpawnEightWayExplosionParticles).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #4,(PlaneAShakeLevel).w
                move.w  (PlaneAShakeLevel).w,(PlaneBShakeLevel).w
                rts
; End of function Boss_Stage3OrbitingFormationCheckDefeat
; Converts the hit flag into a four-frame palette flash
Boss_Stage3OrbitingFormationHandleHitFlash:             ; CODE XREF: Boss_Stage3OrbitingFormationMain+20   p  ; was: sub_34028
                bclr    #6,$22(a5)
                beq.w   Boss_Stage3OrbitingFormationReturn
                move.w  #4,(PlaneAShakeLevel).w
                move.w  (PlaneAShakeLevel).w,(PlaneBShakeLevel).w
                rts
; End of function Boss_Stage3OrbitingFormationHandleHitFlash
; Advances formation angles and horizontal motion
Boss_Stage3OrbitingFormationUpdateMotion:               ; CODE XREF: Boss_Stage3OrbitingFormationMain+14   p  ; was: sub_34040
                move.l  $50(a5),d0
                add.l   d0,$4C(a5)
                andi.l  #$FFFFFF,$4C(a5)
                move.l  $58(a5),d0
                add.l   d0,$54(a5)
                andi.l  #$FFFFFF,$54(a5)
                tst.l   $58(a5)
                beq.s   Boss_Stage3OrbitingFormationApplyHorizontalMotion
                move.w  $5E(a5),d0
                add.w   d0,$5C(a5)
                andi.w  #$FF,$5C(a5)
Boss_Stage3OrbitingFormationApplyHorizontalMotion:      ; CODE XREF: Boss_Stage3OrbitingFormationUpdateMotion+24   j  ; was: loc_34074
                cmpi.w  #$A,4(a5)
                bcs.w   Boss_Stage3OrbitingFormationReturn
                move.l  $50(a5),d0
                asr.l   #2,d0
                tst.l   $18(a5)
                bpl.s   Boss_Stage3OrbitingFormationSetHorizontalVelocity
                neg.l   d0
Boss_Stage3OrbitingFormationSetHorizontalVelocity:      ; CODE XREF: Boss_Stage3OrbitingFormationUpdateMotion+48   j  ; was: loc_3408C
                move.l  d0,$18(a5)
                cmpi.w  #$140,$10(a5)
                bcs.s   Boss_Stage3OrbitingFormationReverseHorizontalMotion
                cmpi.w  #$1A0,$10(a5)
                bhi.s   Boss_Stage3OrbitingFormationReverseHorizontalMotion
                rts
; ---------------------------------------------------------------------------
Boss_Stage3OrbitingFormationReverseHorizontalMotion:    ; CODE XREF: Boss_Stage3OrbitingFormationUpdateMotion+56   j  ; was: loc_340A2
                                        ; Boss_Stage3OrbitingFormationUpdateMotion+5E   j
                neg.l   $18(a5)
                move.l  $18(a5),d0
                add.l   d0,$10(a5)
                rts
; End of function Boss_Stage3OrbitingFormationUpdateMotion
; Applies vertical acceleration and reverses it at the velocity limits
Boss_Stage3OrbitingFormationUpdateVerticalVelocity:     ; CODE XREF: Boss_Stage3OrbitingFormationMain+1C   p  ; was: sub_340B0
                tst.l   (SecondaryEntityWork5C).w
                beq.w   Boss_Stage3OrbitingFormationReturn
                move.l  (SecondaryEntityWork5C).w,d0
                add.l   d0,$1C(a5)
                move.l  $1C(a5),d0
                tst.l   d0
                bmi.s   Boss_Stage3OrbitingFormationCheckVerticalVelocityLimit
                neg.l   d0
Boss_Stage3OrbitingFormationCheckVerticalVelocityLimit:  ; CODE XREF: Boss_Stage3OrbitingFormationUpdateVerticalVelocity+16   j  ; was: loc_340CA
                cmpi.l  #$FFFF8000,d0
                bne.w   Boss_Stage3OrbitingFormationReturn
                neg.l   (SecondaryEntityWork5C).w
                rts
; End of function Boss_Stage3OrbitingFormationUpdateVerticalVelocity
; Recomputes all eight part positions from the formation rotations
Boss_Stage3OrbitingFormationUpdateParts:                ; CODE XREF: Boss_Stage3OrbitingFormationMain+18   p  ; was: sub_340DA
                move.w  #7,d7
                lea     (SecondaryEntityType).w,a0
Boss_Stage3OrbitingFormationUpdateNextPart:             ; CODE XREF: Boss_Stage3OrbitingFormationUpdateParts+98   j  ; was: loc_340E2
                move.w  SecondaryEntityWork4C-SecondaryEntityType(a0),d0
                add.w   $4C(a5),d0
                andi.w  #$FF,d0
                add.w   d0,d0
                lea     (Math_SineTable).l,a1
                move.w  (a1,d0.w),d1
                move.w  -$80(a1,d0.w),d2
                muls.w  $4A(a0),d1
                muls.w  $4A(a0),d2
                swap    d2
                move.w  d2,d5
                move.w  $54(a5),d3
                add.w   d3,d3
                move.w  -$80(a1,d3.w),d4
                muls.w  d4,d2
                asl.l   #2,d2
                move.w  (a1,d3.w),d4
                muls.w  d4,d5
                swap    d5
                andi.w  #$FF,d5
                add.b   $20(a5),d5
                move.b  d5,$20(a0)
                swap    d1
                swap    d2
                move.w  $5C(a5),d0
                add.w   d0,d0
                move.w  (a1,d0.w),d3
                move.w  -$80(a1,d0.w),d4
                muls.w  d1,d3
                muls.w  d2,d4
                sub.l   d4,d3
                asl.l   #2,d3
                move.l  d3,d5
                move.w  (a1,d0.w),d3
                move.w  -$80(a1,d0.w),d4
                muls.w  d1,d4
                muls.w  d2,d3
                add.l   d4,d3
                asl.l   #2,d3
                move.l  d3,d6
                move.l  d5,d1
                move.l  d6,d2
                add.l   $10(a5),d1
                add.l   $14(a5),d2
                move.l  d1,$10(a0)
                move.l  d2,$14(a0)
                adda.w  #$60,a0                         ; '`'
                dbf     d7,Boss_Stage3OrbitingFormationUpdateNextPart
                rts
; End of function Boss_Stage3OrbitingFormationUpdateParts
; Dispatches the formation's ten controller states
Boss_Stage3OrbitingFormationDispatchState:              ; CODE XREF: Boss_Stage3OrbitingFormationMain+4   p  ; was: sub_34178
                move.w  4(a5),d0
                lea     Boss_Stage3OrbitingFormationStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Stage3OrbitingFormationDispatchState
; ---------------------------------------------------------------------------
Boss_Stage3OrbitingFormationStates: dc.w    Boss_Stage3OrbitingFormationInit-*  ; DATA XREF: Boss_Stage3OrbitingFormationDispatchState+4   o  ; was: off_34184
                dc.w    Boss_Stage3OrbitingFormationRemove-*
                dc.w    Boss_Stage3OrbitingFormationWaitForActivationSignal-*
                dc.w    Boss_Stage3OrbitingFormationEnterBattle-*
                dc.w    Boss_Stage3OrbitingFormationWaitForAttackPosition-*
                dc.w    Boss_Stage3OrbitingFormationPrepareHomingShot-*
                dc.w    Boss_Stage3OrbitingFormationFireHomingShot-*
                dc.w    Boss_Stage3OrbitingFormationFirePartRadialShots-*
                dc.w    Boss_Stage3OrbitingFormationWaitBetweenAttacks-*
                dc.w    Boss_Stage3OrbitingFormationRestoreSpin-*

; Initializes the boss controller, its eight parts, and graphics request
Boss_Stage3OrbitingFormationInit:                       ; DATA XREF: ROM:Boss_Stage3OrbitingFormationStates   o  ; was: sub_34198
                move.l  #Boss_Stage3OrbitingFormationSpriteMapping00,8(a5)
                move.w  #$B00,$E(a5)
                move.w  #$CC00,2(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #$200,$10(a5)
                move.w  #$118,$14(a5)
                move.l  #$F010F010,$28(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                move.w  #2,$26(a5)
                clr.w   (BossHealth).w
                move.w  #$28,$24(a5)                    ; '('
                move.b  #6,(BossColorEffectFlags).w
                move.b  #$80,$23(a5)
                move.w  #7,d7
                clr.w   d6
                lea     (SecondaryEntityType).w,a0
Boss_Stage3OrbitingFormationInitNextPart:               ; CODE XREF: Boss_Stage3OrbitingFormationInit+9E   j  ; was: loc_341F2
                move.w  #$10,(a0)
                move.l  #Boss_Stage3OrbitingFormationSpriteMapping01,8(a0)
                move.w  #$B00,$E(a0)
                move.w  #$CC00,2(a0)
                move.b  #$50,$21(a0)                    ; 'P'
                move.w  #2,$26(a0)
                move.l  #$FC04FC04,$28(a0)
                move.b  #$10,$23(a0)
                move.w  d6,$4C(a0)
                move.w  #$BC,$4A(a0)
                addi.w  #$20,d6                         ; ' '
                adda.w  #$60,a0                         ; '`'
                dbf     d7,Boss_Stage3OrbitingFormationInitNextPart
                move.l  #$FFFF8000,$1C(a5)
                move.l  #$800,(SecondaryEntityWork5C).w
                move.w  #4,4(a5)
                movem.l a5,-(sp)
                lea     Boss_Stage3OrbitingFormationTileLoadRequest(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
                movem.l (sp)+,a5
                rts
; End of function Boss_Stage3OrbitingFormationInit
; ---------------------------------------------------------------------------
Boss_Stage3OrbitingFormationTileLoadRequest:    dc.w    7  ; field_0  ; was: stru_34266
                                        ; DATA XREF: Boss_Stage3OrbitingFormationInit+BC   o
                dc.l    Boss_Stage3OrbitingFormationTileArt  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF

; Removes the controller after the defeat transition
Boss_Stage3OrbitingFormationRemove:                     ; DATA XREF: ROM:00034186   o  ; was: sub_34270
                clr.w   (a5)
                rts
; End of function Boss_Stage3OrbitingFormationRemove
; Waits for the Stage 3 activation signal, then starts arena entry motion
Boss_Stage3OrbitingFormationWaitForActivationSignal:    ; DATA XREF: ROM:00034188   o  ; was: sub_34274
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_Stage3OrbitingFormationReturn
                move.w  #$C0,$54(a5)
                move.l  #$40000,$50(a5)
                move.w  #2,$5E(a5)
                move.l  #$FFFF0000,$18(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_Stage3OrbitingFormationWaitForActivationSignal
; Arms boss health when the formation reaches the battle-entry X position
Boss_Stage3OrbitingFormationEnterBattle:                ; DATA XREF: ROM:0003418A   o  ; was: sub_3429E
                cmpi.w  #$1C0,$10(a5)
                bcc.w   Boss_Stage3OrbitingFormationReturn
                move.w  #$1E00,(BossMaxHealth).w
                move.w  #$1E00,(BossHealth).w
                clr.b   (BossColorEffectFlags).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_Stage3OrbitingFormationEnterBattle
; Waits for the attack X position, then enables vertical formation rotation
Boss_Stage3OrbitingFormationWaitForAttackPosition:      ; DATA XREF: ROM:0003418C   o  ; was: sub_342BE
                cmpi.w  #$180,$10(a5)
                bcc.w   Boss_Stage3OrbitingFormationReturn
                move.l  #$8000,$58(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_Stage3OrbitingFormationWaitForAttackPosition
; Selects a random delay for the next aimed homing shot
Boss_Stage3OrbitingFormationPrepareHomingShot:          ; DATA XREF: ROM:0003418E   o  ; was: sub_342D6
                addq.w  #2,4(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                move.w  d0,$48(a5)
                tst.w   (DifficultyMode).w
                bne.w   Boss_Stage3OrbitingFormationReturn
                addi.w  #$40,$48(a5)                    ; '@'
                rts
; End of function Boss_Stage3OrbitingFormationPrepareHomingShot
; Fires an aimed homing shot, then waits for the formation to align
Boss_Stage3OrbitingFormationFireHomingShot:             ; DATA XREF: ROM:00034190   o  ; was: sub_342F6
                subq.w  #1,$48(a5)
                bpl.w   Boss_Stage3OrbitingFormationWaitForOrbitAlignment
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_Stage3OrbitingFormationReturn
                move.w  #$FFE8,d0
                clr.w   d1
                move.w  #$8004,d2
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
                move.w  #$A,4(a5)
Boss_Stage3OrbitingFormationWaitForOrbitAlignment:      ; CODE XREF: Boss_Stage3OrbitingFormationFireHomingShot+4   j  ; was: loc_34326
                tst.l   $54(a5)
                bne.w   Boss_Stage3OrbitingFormationReturn
                eori.b  #1,$4A(a5)
                clr.l   $58(a5)
                move.w  #$E,4(a5)
                rts
; End of function Boss_Stage3OrbitingFormationFireHomingShot
; Stops the spin and fires one radial shot from each orbiting part
Boss_Stage3OrbitingFormationFirePartRadialShots:        ; DATA XREF: ROM:00034192   o  ; was: sub_34340
                subi.l  #$800,$50(a5)
                bne.w   Boss_Stage3OrbitingFormationReturn
                addq.w  #2,4(a5)
                tst.w   (DifficultyMode).w
                beq.w   Boss_Stage3OrbitingFormationReturn
                move.w  #$20,$48(a5)                    ; ' '
                movem.w a5,-(sp)
                lea     (SecondaryEntityType).w,a5
                move.w  #7,d4
Boss_Stage3OrbitingFormationFireFromNextPart:           ; CODE XREF: Boss_Stage3OrbitingFormationFirePartRadialShots+52   j  ; was: loc_3436A
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Stage3OrbitingFormationFinishPartRadialShots
                clr.w   d0
                clr.w   d1
                move.w  #$8004,d2
                move.w  $4C(a5),d6
                add.w   (PrimaryEntityWork4C).w,d6
                andi.w  #$FF,d6
                add.w   d6,d6
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
                adda.w  #$60,a5                         ; '`'
                dbf     d4,Boss_Stage3OrbitingFormationFireFromNextPart
Boss_Stage3OrbitingFormationFinishPartRadialShots:      ; CODE XREF: Boss_Stage3OrbitingFormationFirePartRadialShots+30   j  ; was: loc_34396
                movem.w (sp)+,a5
                rts
; End of function Boss_Stage3OrbitingFormationFirePartRadialShots
; Waits between the radial volley and spin recovery
Boss_Stage3OrbitingFormationWaitBetweenAttacks:         ; DATA XREF: ROM:00034194   o  ; was: sub_3439C
                subq.w  #1,$48(a5)
                bpl.w   Boss_Stage3OrbitingFormationReturn
                addq.w  #2,4(a5)
                rts
; End of function Boss_Stage3OrbitingFormationWaitBetweenAttacks
; Restores the formation spin rate before returning to the aimed-shot cycle
Boss_Stage3OrbitingFormationRestoreSpin:                ; DATA XREF: ROM:00034196   o  ; was: sub_343AA
                addi.l  #$800,$50(a5)
                cmpi.l  #$40000,$50(a5)
                bcs.w   Boss_Stage3OrbitingFormationReturn
                move.l  #$8000,$58(a5)
                move.w  #$A,4(a5)
Boss_Stage3OrbitingFormationReturn:                     ; CODE XREF: Boss_Stage3OrbitingFormationMain+10   j  ; was: locret_343CC
                                        ; Boss_Stage3OrbitingFormationCheckDefeat+6   j
                rts
; End of function Boss_Stage3OrbitingFormationRestoreSpin
