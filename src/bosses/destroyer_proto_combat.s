; Destroyer Proto movement selection and three attack sequences
Boss_DestroyerProtoChooseMovementTarget:                ; was: sub_31830
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                move.w  #$C,d0
                move.w  #$10,d1
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
Boss_DestroyerProtoChooseNextMovementTarget:            ; was: loc_3184C
                                        ; Boss_DestroyerProtoRetreatAfterSpread+24   j
                jsr     (RandomNumber).l
                andi.w  #$1C,d0
                move.w  d0,$54(a5)
                move.w  Boss_DestroyerProtoMovementTargetTable(pc,d0.w),d1
                sub.w   $10(a5),d1
                swap    d1
                clr.w   d1
                asr.l   #7,d1
                move.l  d1,$4C(a5)
                move.w  Boss_DestroyerProtoMovementTargetTable+2(pc,d0.w),d1
                sub.w   $14(a5),d1
                swap    d1
                clr.w   d1
                asr.l   #7,d1
                move.l  d1,$50(a5)
                move.w  #$80,$4A(a5)
                move.w  #8,4(a5)
                rts
; End of function Boss_DestroyerProtoChooseMovementTarget
; ---------------------------------------------------------------------------
Boss_DestroyerProtoMovementTargetTable: dc.w    $C0, $C0, $120, $C0, $180, $C0, $C0, $F8, $180, $F8, $C0, $130, $120, $130, $180, $130  ; was: word_3188C
                                        ; Boss_DestroyerProtoChooseMovementTarget+3C   r

; Accelerates toward the selected target while opening the six parts
Boss_DestroyerProtoMoveToTarget:                        ; was: sub_318AC
                bsr.w   Boss_DestroyerProtoExpandPartRadii
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                move.w  #$C,d0
                move.w  #$10,d1
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                move.l  $4C(a5),d0
                add.l   d0,$18(a5)
                move.l  $50(a5),d0
                add.l   d0,$1C(a5)
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1C,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoMoveToTarget
; Chooses the next twin-shot, spread, or aimed-stream attack
Boss_DestroyerProtoChooseAttack:                        ; was: sub_318EC
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                bsr.w   Boss_DestroyerProtoContractPartRadii
                move.w  #$C,d0
                move.w  #$10,d1
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jsr     (RandomNumber).l
                andi.w  #3,d0
                beq.s   Boss_DestroyerProtoSelectSpreadAttack
                cmpi.w  #1,d0
                beq.w   Boss_DestroyerProtoAimAllPartsAtPlayer
                jsr     (Math_CalculateAngleToPlayer).l
                addi.w  #$10,d2
                andi.w  #$1E0,d2
                move.w  d2,(QuaternaryEntityWork40).w
                move.w  d2,(QuaternaryEntityWork46).w
                move.w  d2,(SeventhEntityWork40).w
                move.w  d2,(SeventhEntityWork46).w
                jsr     (RandomNumber).l
                andi.w  #$60,d0                         ; '`'
                addi.w  #$20,d0                         ; ' '
                sub.w   d0,d2
                andi.w  #$1FE,d2
                move.w  d2,(SecondaryEntityWork40).w
                move.w  d2,(TertiaryEntityWork40).w
                add.w   d0,d2
                add.w   d0,d2
                andi.w  #$1FE,d2
                move.w  d2,(FifthEntityWork40).w
                move.w  d2,(SixthEntityWork40).w
                move.w  #$1C,$4A(a5)
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_DestroyerProtoSelectSpreadAttack:                  ; was: loc_3197E
                move.w  #$1C,$4A(a5)
                move.w  #$16,4(a5)
                rts
; End of function Boss_DestroyerProtoChooseAttack
; Opens all parts and waits before the twin-shot flash
Boss_DestroyerProtoOpenPartsForTwinShot:                ; was: sub_3198C
                bsr.w   Boss_DestroyerProtoExpandPartRadii
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoOpenPartsForTwinShot
; Advances the twin-shot palette phase and launches two part-based projectiles
Boss_DestroyerProtoLaunchTwinShots:                     ; was: sub_3199E
                move.w  #$2000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                addq.w  #1,$4A(a5)
                cmpi.w  #$E,$4A(a5)
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_DestroyerProtoLaunchTwinProjectiles
                move.b  #$EA,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoLaunchTwinShots
; Reverses the twin-shot palette phase
Boss_DestroyerProtoFadeTwinShots:                       ; was: sub_319CC
                move.w  #$2000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$20,$4A(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoFadeTwinShots
; Waits after the twin-shot flash
Boss_DestroyerProtoWaitAfterTwinShots:                  ; was: sub_319EC
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1C,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoWaitAfterTwinShots
; Closes the parts and returns to movement-target selection
Boss_DestroyerProtoRetreatAfterTwinShots:               ; was: sub_31A00
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                bsr.w   Boss_DestroyerProtoContractPartRadii
                move.w  #$C,d0
                move.w  #$10,d1
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_DestroyerProtoSynchronizePartAngles
                bra.w   Boss_DestroyerProtoChooseNextMovementTarget
; End of function Boss_DestroyerProtoRetreatAfterTwinShots
; Opens the parts while rotating them in opposite directions
Boss_DestroyerProtoOpenPartsForSpread:                  ; was: sub_31A28
                bsr.w   Boss_DestroyerProtoExpandPartRadii
                move.w  #$FFF8,d0
                move.w  #$20,d1                         ; ' '
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoOpenPartsForSpread
; Rotates the open parts and charges the spread palette
Boss_DestroyerProtoChargeSpread:                        ; was: sub_31A46
                move.w  #$FFF8,d0
                move.w  #$20,d1                         ; ' '
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                move.w  #$8000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                addq.w  #1,$4A(a5)
                cmpi.w  #$E,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$80,$4A(a5)
                move.b  #$56,d0                         ; 'V'
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoChargeSpread
; Emits a timed spread while continuing the part rotation
Boss_DestroyerProtoFireSpread:                          ; was: sub_31A7E
                move.w  #$FFF8,d0
                move.w  #$20,d1                         ; ' '
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoSpawnSpreadProjectile
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$E,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoFireSpread
; Allocates one velocity-table projectile for the active spread step
Boss_DestroyerProtoSpawnSpreadProjectile:               ; was: sub_31AA2
                move.w  $4A(a5),d0
                andi.w  #1,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                lea     Projectile_DestroyerProtoVelocityXTable(pc),a1
                nop
                lea     Projectile_DestroyerProtoVelocityYTable(pc),a2
                nop
                move.w  $4A(a5),d0
                andi.w  #$E,d0
                lsl.w   #2,d0
                move.w  $4A(a5),d1
                andi.w  #$10,d1
                lsr.w   #2,d1
                add.w   d1,d0
                move.w  (a1,d0.w),$18(a0)
                move.w  (a2,d0.w),$1C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$3B8,(a0)
                jsr     (RandomNumber).l
                andi.w  #$F,d0
                beq.s   Projectile_DestroyerProtoInitSpreadShot
Projectile_InitSharedHitReactiveShot:                   ; was: loc_31B02
                                        ; Boss_VictorSpawnSplitShotWave+4E   p
                move.w  #$EC00,2(a0)
                move.l  #SharedCombatSpriteAnimation16,8(a0)
                clr.w   $C(a0)
                move.w  #$8480,$E(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FC04FC04,$2C(a0)
                move.w  #$46,$26(a0)                    ; 'F'
                move.w  #8,$48(a0)
                move.w  #0,4(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_DestroyerProtoInitSpreadShot:                ; was: loc_31B3C
                move.w  #$CC00,2(a0)
                move.l  #Shared_AsteroidAndDestroyerProtoMapping,8(a0)
                move.w  #$400,$E(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$F010F010,$2C(a0)
                move.w  #$64,$26(a0)                    ; 'd'
                move.w  #6,$48(a0)
                move.w  #8,4(a0)
                rts
; End of function Boss_DestroyerProtoSpawnSpreadProjectile
; Reverses the spread palette phase
Boss_DestroyerProtoRecoverSpread:                       ; was: sub_31B72
                move.w  #$FFF8,d0
                move.w  #$20,d1                         ; ' '
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                move.w  #$8000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1C,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoRecoverSpread
; Closes the parts and returns from the spread attack
Boss_DestroyerProtoRetreatAfterSpread:                  ; was: sub_31B9A
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                bsr.w   Boss_DestroyerProtoContractPartRadii
                move.w  #$FFF8,d0
                move.w  #$20,d1                         ; ' '
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_DestroyerProtoSynchronizePartAngles
                bra.w   Boss_DestroyerProtoChooseNextMovementTarget
; End of function Boss_DestroyerProtoRetreatAfterSpread
; Aims all six parts at the player and enters the stream attack
Boss_DestroyerProtoAimAllPartsAtPlayer:                 ; was: sub_31BC2
                jsr     (Math_CalculateAngleToPlayer).l
                addi.w  #$10,d2
                andi.w  #$1E0,d2
                move.w  d2,(SecondaryEntityWork40).w
                move.w  d2,(TertiaryEntityWork40).w
                move.w  d2,(QuaternaryEntityWork40).w
                move.w  d2,(QuaternaryEntityWork46).w
                move.w  d2,(FifthEntityWork40).w
                move.w  d2,(SixthEntityWork40).w
                move.w  d2,(SeventhEntityWork40).w
                move.w  d2,(SeventhEntityWork46).w
                move.w  #$1C,$4A(a5)
                move.w  #$20,4(a5)                      ; ' '
                rts
; End of function Boss_DestroyerProtoAimAllPartsAtPlayer
; Opens all parts before the aimed stream
Boss_DestroyerProtoOpenPartsForStream:                  ; was: sub_31BFE
                bsr.w   Boss_DestroyerProtoExpandPartRadii
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoOpenPartsForStream
; Charges the aimed stream and initializes its two fixed-slot cursors
Boss_DestroyerProtoChargeStream:                        ; was: sub_31C10
                move.w  #$C000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                addq.w  #1,$4A(a5)
                cmpi.w  #$E,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.l  #EighthEntityType,$58(a5)
                move.l  #TwentyFourthEntityType,$5C(a5)
                move.w  #$10,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoChargeStream
; Waits before firing the aimed stream
Boss_DestroyerProtoWaitBeforeStream:                    ; was: sub_31C42
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$41,$4A(a5)                    ; 'A'
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoWaitBeforeStream
; Rotates the six parts and fires paired stream projectiles
Boss_DestroyerProtoFireStream:                          ; was: sub_31C56
                bsr.w   Boss_DestroyerProtoRotatePartsForStream
                bsr.w   Boss_DestroyerProtoFireNextStreamPair
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$E,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoFireStream
; Activates the next fixed-slot projectile for each inner part
Boss_DestroyerProtoFireNextStreamPair:                  ; was: sub_31C72
                move.w  $4A(a5),d0
                cmpi.w  #$40,d0                         ; '@'
                bcc.w   Entity_UpdateReturn
                cmpi.w  #$C,d0
                bcs.w   Entity_UpdateReturn
                andi.w  #3,d0
                bne.w   Entity_UpdateReturn
                lea     (QuaternaryEntityType).w,a4
                movea.l $58(a5),a0
                addi.l  #$60,$58(a5)                    ; '`'
                bsr.w   Projectile_DestroyerProtoActivateStreamShot
                move.b  #$CE,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SeventhEntityType).w,a4
                movea.l $5C(a5),a0
                addi.l  #$60,$5C(a5)                    ; '`'
; End of function Boss_DestroyerProtoFireNextStreamPair
; Activates one preinitialized stream projectile
Projectile_DestroyerProtoActivateStreamShot:            ; was: sub_31CBC
                bsr.w   Projectile_DestroyerProtoInitFromPart
                move.l  $4C(a0),$18(a0)
                move.l  $50(a0),$1C(a0)
                move.w  $54(a0),d0
                lea     Projectile_DestroyerProtoMappingFrameTable(pc),a1
                nop
                move.l  (a1,d0.w),8(a0)
                lsr.w   #1,d0
                lea     Projectile_DestroyerProtoSpriteAttributeTable(pc),a1
                nop
                move.w  (a1,d0.w),$E(a0)
                move.w  #$CC00,2(a0)
                move.w  #2,4(a0)
                rts
; End of function Projectile_DestroyerProtoActivateStreamShot
; Rotates all six parts during the aimed stream
Boss_DestroyerProtoRotatePartsForStream:                ; was: sub_31CF8
                move.w  #2,d0
                lea     (SecondaryEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddOuterPartAngle
                move.w  #4,d0
                lea     (TertiaryEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddOuterPartAngle
                move.w  #8,d1
                lea     (QuaternaryEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddInnerPartAngles
                move.w  #$FFFE,d0
                lea     (FifthEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddOuterPartAngle
                move.w  #$FFFC,d0
                lea     (SixthEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddOuterPartAngle
                move.w  #$FFF8,d1
                lea     (SeventhEntityType).w,a4
                bsr.w   Boss_DestroyerProtoAddInnerPartAngles
                rts
; End of function Boss_DestroyerProtoRotatePartsForStream
; Reverses the aimed-stream palette phase
Boss_DestroyerProtoFadeStream:                          ; was: sub_31D42
                move.w  #$C000,d7
                bsr.w   Boss_DestroyerProtoApplyPaletteFade
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$20,$4A(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoFadeStream
; Waits after the aimed stream
Boss_DestroyerProtoWaitAfterStream:                     ; was: sub_31D5E
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1C,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoWaitAfterStream
; Closes the parts and returns from the aimed stream
Boss_DestroyerProtoRetreatAfterStream:                  ; was: sub_31D72
                bsr.w   Boss_DestroyerProtoUpdateCircularVelocity
                bsr.w   Boss_DestroyerProtoContractPartRadii
                move.w  #$C,d0
                move.w  #$10,d1
                bsr.w   Boss_DestroyerProtoUpdatePartAngles
                bsr.w   Boss_DestroyerProtoUpdateViewportOffset
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_DestroyerProtoSynchronizePartAngles
                bra.w   Boss_DestroyerProtoChooseNextMovementTarget
; End of function Boss_DestroyerProtoRetreatAfterStream
