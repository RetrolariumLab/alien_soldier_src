; Adjacent type-$164 no-op followed by the shared small/large health pickups
Entity_Type164NoOp:                                     ; was: nullsub_6
                rts
; End of function Entity_Type164NoOp
; Creates the small pickup variant from the current object
Pickup_SpawnSmallFromCurrentObject:                     ; was: sub_2BCFE
                                        ; sub_2B298:Projectile_ConvertTwoSpeedShotToPickup   p
                movea.w a5,a0
Pickup_SpawnSmall:                                      ; was: loc_2BD00
                                        ; Effect_InitializeWolfGaropaBoundaryPair+64   p
                moveq   #0,d7
                bra.w   Pickup_InitializeSelectedSize
; End of function Pickup_SpawnSmallFromCurrentObject
; Unreferenced alternate entry that creates a small pickup through the thunk
UnreferencedPickup_SpawnSmallFromCurrentObjectViaThunk:
                movea.w a5,a0                           ; was: sub_2BD06
                moveq   #0,d7
                bra.w   Pickup_InitializeSelectedSizeThunk
; End of function UnreferencedPickup_SpawnSmallFromCurrentObjectViaThunk
; Unreferenced entry that creates the large pickup from the current object
UnreferencedPickup_SpawnLargeFromCurrentObject:
                movea.w a5,a0                           ; was: sub_2BD0E
; End of function UnreferencedPickup_SpawnLargeFromCurrentObject
Pickup_SpawnLarge:                                      ; was: sub_2BD10
                                        ; Projectile_JetsripperMain+46   p
                moveq   #1,d7
                bra.w   Pickup_InitializeSelectedSize
; End of function Pickup_SpawnLarge
; Unreferenced alternate entry that creates a large pickup through the thunk
UnreferencedPickup_SpawnLargeFromCurrentObjectViaThunk:
                movea.w a5,a0                           ; was: sub_2BD16
Pickup_SelectLargeSize:                                 ; was: loc_2BD18
                                        ; Projectile_UpdateArtemisRadialEmitter+EC   p
                moveq   #1,d7
                bra.w   Pickup_InitializeSelectedSizeThunk
; End of function UnreferencedPickup_SpawnLargeFromCurrentObjectViaThunk
; Selects a pickup size randomly with the caller-provided mask
Pickup_SpawnRandomFromCurrentObject:                    ; was: sub_2BD1E
                                        ; Enemy_EggSpitterController+18   j
                movea.w a5,a0
Pickup_SelectRandomSize:                                ; was: loc_2BD20
                                        ; Boss_WolfGaropaSpawnFiniteRewardPickups+2A   p
                moveq   #0,d7
                move.w  (RandomNumberState).w,d1
                and.w   d0,d1
                beq.s   Pickup_SelectLargeSize
                bra.w   *+4
; End of function Pickup_SpawnRandomFromCurrentObject
; Attributes: thunk
Pickup_InitializeSelectedSizeThunk:                     ; was: sub_2BD2E
                                        ; UnreferencedPickup_SpawnLargeFromCurrentObjectViaThunk+4   j
                bra.s   Pickup_InitializeSelectedSize
; End of function Pickup_InitializeSelectedSizeThunk
; Unreferenced entry that suppresses creation only when health equals maximum
UnreferencedPickup_InitializeSelectedSizeIfHealthDiffersFromMax:
                move.w  (PlayerHealth).w,d0             ; was: sub_2BD30
                cmp.w   (PlayerMaxHealth).w,d0
                bne.s   Pickup_InitializeSelectedSize
Pickup_DeactivateTargetObject:                          ; was: loc_2BD3A
                move.w  #$10,(a0)
                bset    #4,2(a0)
                rts
; ---------------------------------------------------------------------------
; Initializes the selected pickup size in the target object
Pickup_InitializeSelectedSize:                          ; was: loc_2BD46
                                        ; Pickup_SpawnLarge+2   j
                cmpi.w  #6,(ActivePickupCountMinus1).w
                bpl.s   Pickup_DeactivateTargetObject
                move.w  #$194,(a0)
                move.w  #$E140,2(a0)
                move.w  #$480,d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a0)
                clr.w   $C(a0)
                clr.b   $20(a0)
                move.b  #$40,$21(a0)                    ; '@'
                clr.b   $22(a0)
                move.b  #$20,$23(a0)                    ; ' '
                move.l  #$FA06FA06,$2C(a0)
                move.b  Pickup_SoundIds(pc,d7.w),$4C(a0)
                asl.w   #1,d7
                move.w  Pickup_HealthRestoreAmounts(pc,d7.w),$48(a0)
                asl.w   #1,d7
                move.l  Pickup_SpriteMappings(pc,d7.w),8(a0)
                move.w  #$A0,$4A(a0)
                rts
; End of function Pickup_InitializeSelectedSize
; ---------------------------------------------------------------------------
Pickup_SoundIds:                dc.b    $46, $47        ; was: byte_2BDA2
Pickup_HealthRestoreAmounts:    dc.w    $1E, $64        ; was: word_2BDA4
Pickup_SpriteMappings:          dc.l    Effect_SpriteAnimation28  ; was: off_2BDA8
                dc.l    Effect_SpriteAnimation27

; Updates health-pickup lifetime, collection, display priority, and motion
Pickup_Update:                                          ; was: sub_2BDB0
                subq.w  #1,$4A(a5)
                bmi.s   Pickup_Remove
                cmpi.w  #$20,$4A(a5)                    ; ' '
                bpl.s   Pickup_CheckCollection
                bset    #7,2(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Pickup_CheckCollection
                bclr    #7,2(a5)
Pickup_CheckCollection:                                 ; was: loc_2BDD2
                                        ; Pickup_Update+1A   j
                bclr    #7,$22(a5)
                beq.s   Pickup_UpdateFlipAndStageMotion
                bclr    #4,$22(a5)
                bne.s   Pickup_UpdateFlipAndStageMotion
                move.b  $4C(a5),d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #$500,d0
                jsr     (Score_AddPackedBCD).l
                move.w  (PlayerHealth).w,d0
                beq.s   Pickup_StoreHealthAndStartDeltaDisplay
                bmi.s   Pickup_StoreHealthAndStartDeltaDisplay
                add.w   $48(a5),d0
                cmp.w   (PlayerMaxHealth).w,d0
                bmi.s   Pickup_StoreHealthAndStartDeltaDisplay
                move.w  (PlayerMaxHealth).w,d0
Pickup_StoreHealthAndStartDeltaDisplay:                 ; was: loc_2BE0E
                                        ; Pickup_Update+4E   j
                move.w  d0,(PlayerHealth).w
                move.w  $48(a5),(HealthDeltaDisplayValue).w
                move.w  #$30,(HealthDeltaDisplayTimer).w  ; '0'
Pickup_Remove:                                          ; was: loc_2BE1E
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Pickup_UpdateFlipAndStageMotion:                        ; was: loc_2BE26
                                        ; Pickup_Update+30   j
                andi.w  #$E7FF,$E(a5)
                lea     (SpriteFlipBitsTable).l,a0
                move.w  (FrameCounter).w,d0
                asr.w   #1,d0
                andi.w  #6,d0
                move.w  (a0,d0.w),d0
                or.w    d0,$E(a5)
                move.l  (StageMotionXDelta).w,d0
                add.l   d0,$10(a5)
                move.l  (StageMotionYDelta).w,d0
                add.l   d0,$14(a5)
                rts
; End of function Pickup_Update
