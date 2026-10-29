; Stage 21 asteroid-field controller, rocks, ambient objects, and debris
Stage21_AsteroidFieldControllerMain:                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_330A6
                tst.w   4(a5)
                beq.s   Stage21_AsteroidFieldUpdateDirection
                cmpi.b  #$80,(SceneSequenceFlags).w
                beq.s   Stage21_AsteroidFieldUpdateDirection
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Stage21_AsteroidFieldUpdateDirection:                   ; CODE XREF: Stage21_AsteroidFieldControllerMain+4   j  ; was: loc_330BC
                                        ; Stage21_AsteroidFieldControllerMain+C   j
                btst    #7,(AsteroidVScrollSpeed).w
                beq.s   Stage21_AsteroidFieldSelectAlternateSide
                btst    #7,(AsteroidFieldVelocity).w
                beq.s   Stage21_AsteroidFieldSelectAlternateSide
                bclr    #0,(SharedScratchLong4).w
                bra.s   Stage21_AsteroidFieldSpawnAndDispatch
; ---------------------------------------------------------------------------
Stage21_AsteroidFieldSelectAlternateSide:               ; CODE XREF: Stage21_AsteroidFieldControllerMain+1C   j  ; was: loc_330D4
                                        ; Stage21_AsteroidFieldControllerMain+24   j
                bset    #0,(SharedScratchLong4).w
Stage21_AsteroidFieldSpawnAndDispatch:                  ; CODE XREF: Stage21_AsteroidFieldControllerMain+2C   j  ; was: loc_330DA
                bsr.w   Stage21_AsteroidFieldSpawnAmbientRock
                move.w  4(a5),d0
                lea     Stage21_AsteroidFieldStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage21_AsteroidFieldControllerMain
; ---------------------------------------------------------------------------
Stage21_AsteroidFieldStates:    dc.w    Stage21_AsteroidFieldInit-*  ; DATA XREF: Stage21_AsteroidFieldControllerMain+3C   o  ; was: off_330EA
                dc.w    Stage21_AsteroidFieldWaitForNegativeVScroll-*
                dc.w    Stage21_AsteroidFieldSpawnRock-*
                dc.w    Stage21_AsteroidFieldWaitThenSelectSpawnPoint-*

; Initializes the Stage 21 asteroid-field controller
Stage21_AsteroidFieldInit:                              ; DATA XREF: ROM:Stage21_AsteroidFieldStates   o  ; was: sub_330F2
                addq.w  #2,4(a5)
                move.w  #$E000,2(a5)
                move.l  #SharedCombatSpriteAnimation12,8(a5)
                move.w  #$8480,$E(a5)
                move.w  #$1B0,$10(a5)
                move.w  #$170,$14(a5)
                move.w  (RandomNumberState).w,$5C(a5)
                andi.w  #3,$5C(a5)
                rts
; End of function Stage21_AsteroidFieldInit
; Waits for the negative V-scroll direction and a speed of at least four pixels
Stage21_AsteroidFieldWaitForNegativeVScroll:            ; DATA XREF: ROM:000330EC   o  ; was: sub_33124
                btst    #0,(SharedScratchLong4).w
                bne.s   Stage21_AsteroidFieldWaitForNegativeVScroll_Return
                cmpi.w  #$FFFC,(AsteroidVScrollSpeed).w
                bgt.s   Stage21_AsteroidFieldWaitForNegativeVScroll_Return
                addq.w  #2,4(a5)
Stage21_AsteroidFieldWaitForNegativeVScroll_Return:     ; CODE XREF: Stage21_AsteroidFieldWaitForNegativeVScroll+6   j  ; was: locret_33138
                                        ; Stage21_AsteroidFieldWaitForNegativeVScroll+E   j
                rts
; End of function Stage21_AsteroidFieldWaitForNegativeVScroll
; Allocates the next large or small asteroid according to the variant schedule
Stage21_AsteroidFieldSpawnRock:                         ; DATA XREF: ROM:000330EE   o  ; was: sub_3313A
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage21_AsteroidFieldSpawnReturn
                addq.w  #2,4(a5)
                bsr.w   Stage21_AsteroidFieldSetSpawnDelayFromVScrollSpeed
                bsr.w   Stage21_InitializeAsteroidObject
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                addq.w  #1,$5C(a5)
                move.w  $5C(a5),d0
                andi.w  #$3F,d0                         ; '?'
                add.w   d0,d0
                move.w  Stage21_AsteroidVariantSchedule(pc,d0.w),d0
                beq.s   Stage21_AsteroidFieldConfigureSmallRock
                move.l  #Stage21_AsteroidLargeMapping,8(a0)
                move.b  #1,$5E(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.l  #$E818E818,$28(a0)
                rts
; ---------------------------------------------------------------------------
Stage21_AsteroidFieldConfigureSmallRock:                ; CODE XREF: Stage21_AsteroidFieldSpawnRock+32   j  ; was: loc_3318E
                move.l  #Shared_AsteroidAndDestroyerProtoMapping,8(a0)
                move.b  #0,$5E(a0)
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F010F010,$28(a0)
Stage21_AsteroidFieldSpawnReturn:                       ; CODE XREF: Stage21_AsteroidFieldSpawnRock+6   j  ; was: locret_331AC
                rts
; End of function Stage21_AsteroidFieldSpawnRock
; ---------------------------------------------------------------------------
Stage21_AsteroidVariantSchedule:    dc.w    1, 0, 0, 0, 1, 0, 0, 0  ; was: word_331AE
                                        ; DATA XREF: Stage21_AsteroidFieldSpawnRock+2E   r
                dc.w    1, 0, 0, 0, 0, 0, 0, 0
                dc.w    0, 0, 0, 1, 0, 0, 0, 1
                dc.w    0, 0, 0, 1, 0, 0, 0, 0
                dc.w    0, 1, 0, 0, 0, 1, 0, 0
                dc.w    0, 1, 0, 0, 0, 0, 0, 0
                dc.w    0, 0, 1, 0, 0, 0, 1, 0
                dc.w    0, 0, 1, 0, 0, 0, 1, 0

; Derives the next asteroid spawn delay from the absolute V-scroll speed
Stage21_AsteroidFieldSetSpawnDelayFromVScrollSpeed:     ; CODE XREF: Stage21_AsteroidFieldSpawnRock+C   p  ; was: sub_3322E
                move.l  (AsteroidVScrollSpeed).w,d0
                bpl.s   Stage21_AsteroidFieldUseVScrollSpeedMagnitude
                neg.l   d0
Stage21_AsteroidFieldUseVScrollSpeedMagnitude:          ; CODE XREF: Stage21_AsteroidFieldSetSpawnDelayFromVScrollSpeed+4   j  ; was: loc_33236
                swap    d0
                andi.w  #$E,d0
                move.w  Stage21_AsteroidSpawnIntervalTable(pc,d0.w),$48(a5)
                rts
; End of function Stage21_AsteroidFieldSetSpawnDelayFromVScrollSpeed
; ---------------------------------------------------------------------------
Stage21_AsteroidSpawnIntervalTable: dc.w    $30, $20, $18, $10, $C, 8, 4, 2, 2, 2  ; was: word_33244
                                        ; DATA XREF: Stage21_AsteroidFieldSetSpawnDelayFromVScrollSpeed+E   r

; Waits for the spawn delay, then selects coordinates from the schedule and RNG
Stage21_AsteroidFieldWaitThenSelectSpawnPoint:          ; DATA XREF: ROM:000330F0   o  ; was: sub_33258
                subq.w  #1,$48(a5)
                bne.s   Stage21_AsteroidFieldWaitThenSelectSpawnPoint_Return
                lea     Stage21_AsteroidSpawnPointTable(pc),a1
                nop
                move.w  $5C(a5),d0
                andi.w  #3,d0
                lsl.w   #4,d0
                lea     (a1,d0.w),a1
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                add.w   d0,d0
                move.w  (a1,d0.w),$10(a5)
                move.w  2(a1,d0.w),$14(a5)
                subq.w  #2,4(a5)
Stage21_AsteroidFieldWaitThenSelectSpawnPoint_Return:   ; CODE XREF: Stage21_AsteroidFieldWaitThenSelectSpawnPoint+4   j  ; was: locret_3328E
                rts
; End of function Stage21_AsteroidFieldWaitThenSelectSpawnPoint
; ---------------------------------------------------------------------------
Stage21_AsteroidSpawnPointTable:    dc.w    $B0, $170, $D0, $170, $F0, $170, $110, $170, $130, $170, $150, $170, $170, $170, $190, $170  ; was: word_33290
                                        ; DATA XREF: Stage21_AsteroidFieldWaitThenSelectSpawnPoint+6   o
                dc.w    $1B0, $170, $1D0, $170, $1D0, $150, $1D0, $130, $1D0, $110, $1D0, $F0, $1D0, $D0, $1D0, $B0

; Updates an asteroid's acceleration, bounds, collision, or ambient-rock mode
Stage21_AsteroidMain:                                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_332D0
                btst    #0,$5F(a5)
                bne.w   Stage21_AmbientRockUpdateDriftAndLifetime
                tst.w   4(a5)
                beq.s   Stage21_AsteroidDispatchCollisionState
                btst    #0,$5E(a5)
                bne.s   Stage21_AsteroidAccelerateSmall
                cmpi.l  #$FFFD8000,$18(a5)
                ble.s   Stage21_AsteroidAccelerateLargeVertically
                addi.l  #-$2000,$18(a5)
Stage21_AsteroidAccelerateLargeVertically:              ; CODE XREF: Stage21_AsteroidMain+20   j  ; was: loc_332FA
                cmpi.l  #$FFFEC000,$1C(a5)
                ble.s   Stage21_AsteroidCheckUpperBounds
                addi.l  #-$2000,$1C(a5)
                bra.s   Stage21_AsteroidCheckUpperBounds
; ---------------------------------------------------------------------------
Stage21_AsteroidAccelerateSmall:                        ; CODE XREF: Stage21_AsteroidMain+16   j  ; was: loc_3330E
                cmpi.l  #$FFFE0000,$18(a5)
                ble.s   Stage21_AsteroidClampSmallHorizontalSpeed
                addi.l  #-$2000,$18(a5)
Stage21_AsteroidClampSmallHorizontalSpeed:              ; CODE XREF: Stage21_AsteroidMain+46   j  ; was: loc_33320
                cmpi.l  #$FFFF0000,$1C(a5)
                ble.s   Stage21_AsteroidCheckUpperBounds
                addi.l  #-$2000,$1C(a5)
Stage21_AsteroidCheckUpperBounds:                       ; CODE XREF: Stage21_AsteroidMain+32   j  ; was: loc_33332
                                        ; Stage21_AsteroidMain+3C   j
                cmpi.w  #$60,$10(a5)                    ; '`'
                blt.w   Stage21_DeactivateAsteroidOutsideUpperLeftBounds
                cmpi.w  #$60,$14(a5)                    ; '`'
                blt.w   Stage21_DeactivateAsteroidOutsideUpperLeftBounds
Stage21_AsteroidDispatchCollisionState:                 ; CODE XREF: Stage21_AsteroidMain+E   j  ; was: loc_33346
                move.w  4(a5),d0
                lea     Stage21_AsteroidCollisionStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage21_AsteroidMain
; ---------------------------------------------------------------------------
Stage21_AsteroidCollisionStates:    dc.w    Stage21_AsteroidInitMotionAndCollision-*  ; DATA XREF: Stage21_AsteroidMain+7A   o  ; was: off_33352
                dc.w    Stage21_AsteroidHandleCollision-*
                dc.w    Stage21_AsteroidInactiveState-*

; Initializes large or small asteroid motion and collision fields
Stage21_AsteroidInitMotionAndCollision:                 ; DATA XREF: ROM:Stage21_AsteroidCollisionStates   o  ; was: sub_33358
                clr.w   $48(a5)
                addq.w  #2,4(a5)
                btst    #0,$5E(a5)
                bne.s   Stage21_AsteroidInitSmallMotion
                move.w  #$64,$26(a5)                    ; 'd'
                move.l  #$FFFD8000,$18(a5)
                move.l  #$FFFEC000,$1C(a5)
                bra.s   Stage21_AsteroidHandleCollision
; ---------------------------------------------------------------------------
Stage21_AsteroidInitSmallMotion:                        ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+E   j  ; was: loc_33380
                move.w  #$C8,$26(a5)
                move.l  #$FFFE0000,$18(a5)
                move.l  #$FFFF0000,$1C(a5)
; Handles asteroid collision, destruction, and rebound response
Stage21_AsteroidHandleCollision:                        ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+26   j  ; was: loc_33396
                                        ; DATA XREF: ROM:00033354   o
                bclr    #7,$22(a5)
                beq.s   Stage21_AsteroidCollisionReturn
                bclr    #4,$22(a5)
                beq.s   Stage21_AsteroidApplyLargeHitResponse
                move.b  #$32,d0                         ; '2'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Stage21_AsteroidSpawnDestructionResult
Stage21_AsteroidApplyLargeHitResponse:                  ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+4C   j  ; was: loc_333B4
                btst    #0,$5E(a5)
                bne.s   Stage21_AsteroidApplySmallHitResponse
                move.l  #$FFFFA000,$4C(a5)
                move.l  #$10000,$18(a5)
                move.l  #$FFFC0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Stage21_AsteroidApplySmallHitResponse:                  ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+62   j  ; was: loc_333D6
                move.l  #$FFFFE800,$4C(a5)
                move.l  #$FFFFE800,$50(a5)
                move.l  $18(a5),d0
                move.l  $1C(a5),d1
                neg.l   d0
                neg.l   d1
                asr.l   #1,d0
                asr.l   #1,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
Stage21_AsteroidCollisionReturn:                        ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+44   j  ; was: locret_333FE
                rts
; End of function Stage21_AsteroidInitMotionAndCollision
Stage21_AsteroidInactiveState:                          ; DATA XREF: ROM:00033356   o  ; was: nullsub_75
                rts
; End of function Stage21_AsteroidInactiveState

; Spawns either a reward pickup or delayed asteroid debris on destruction
Stage21_AsteroidSpawnDestructionResult:                 ; CODE XREF: Stage21_AsteroidInitMotionAndCollision+58   p  ; was: sub_33402
                tst.w   $48(a5)
                bne.w   Stage21_AsteroidDestructionReturn
                move.w  #1,$48(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Stage21_AsteroidDestructionReturn
                tst.w   (DifficultyMode).w
                beq.s   Stage21_AsteroidUseDenseRewardMask
                move.w  #3,d1
                bra.s   Stage21_AsteroidChooseDestructionResult
; ---------------------------------------------------------------------------
Stage21_AsteroidUseDenseRewardMask:                     ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+1C   j  ; was: loc_33426
                move.w  #$F,d1
Stage21_AsteroidChooseDestructionResult:                ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+22   j  ; was: loc_3342A
                move.b  (RandomNumberState).w,d0
                and.w   d1,d0
                beq.s   Stage21_AsteroidSpawnDebris
                btst    #0,$5E(a5)
                bne.s   Stage21_AsteroidSelectSmallReward
                move.w  #1,d0
                bra.s   Stage21_AsteroidSpawnReward
; ---------------------------------------------------------------------------
Stage21_AsteroidSelectSmallReward:                      ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+36   j  ; was: loc_33440
                move.w  #0,d0
Stage21_AsteroidSpawnReward:                            ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+3C   j  ; was: loc_33444
                jsr     (Pickup_SelectRandomSize).l
                bset    #3,2(a0)
                bset    #2,2(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a0)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                move.l  d0,$1C(a0)
                rts
; ---------------------------------------------------------------------------
Stage21_AsteroidSpawnDebris:                            ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+2E   j  ; was: loc_33482
                bsr.w   Projectile_Stage21AsteroidDebrisInit
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$4C(a0)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                move.l  d0,$50(a0)
Stage21_AsteroidDestructionReturn:                      ; CODE XREF: Stage21_AsteroidSpawnDestructionResult+4   j  ; was: locret_334B0
                                        ; Stage21_AsteroidSpawnDestructionResult+14   j
                rts
; End of function Stage21_AsteroidSpawnDestructionResult
; Updates an ambient rock from half the two scroll velocities and expires it
Stage21_AmbientRockUpdateDriftAndLifetime:              ; CODE XREF: Stage21_AsteroidMain+6   j  ; was: sub_334B2
                move.l  (AsteroidVScrollSpeed).w,d0
                move.l  (AsteroidFieldVelocity).w,d1
                asr.l   #1,d0
                asr.l   #1,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                subq.w  #1,$48(a5)
                bne.s   Stage21_AmbientRockUpdateDriftAndLifetime_Return
                ori.w   #$200,2(a5)
Stage21_AmbientRockUpdateDriftAndLifetime_Return:       ; CODE XREF: Stage21_AmbientRockUpdateDriftAndLifetime+18   j  ; was: locret_334D2
                rts
; End of function Stage21_AmbientRockUpdateDriftAndLifetime
; Deactivates an asteroid after it crosses the upper or left arena boundary
Stage21_DeactivateAsteroidOutsideUpperLeftBounds:       ; CODE XREF: Stage21_AsteroidMain+68   j  ; was: sub_334D4
                                        ; Stage21_AsteroidMain+72   j
                move.w  #$1000,2(a5)
                rts
; End of function Stage21_DeactivateAsteroidOutsideUpperLeftBounds
; Initializes fields shared by spawned Stage 21 asteroids and ambient rocks
Stage21_InitializeAsteroidObject:                       ; CODE XREF: Stage21_AsteroidFieldSpawnRock+10   p  ; was: sub_334DC
                                        ; Stage21_AsteroidFieldSpawnAmbientRock+12   p
                move.w  #$3B0,(a0)
                move.w  #$CC00,2(a0)
                move.w  #$6400,$E(a0)
                move.b  #$C0,$21(a0)
                move.b  #$10,$23(a0)
                clr.w   $C(a0)
                rts
; End of function Stage21_InitializeAsteroidObject
; Periodically creates a non-colliding ambient rock at a table-selected position
Stage21_AsteroidFieldSpawnAmbientRock:                  ; CODE XREF: Stage21_AsteroidFieldControllerMain:Stage21_AsteroidFieldSpawnAndDispatch   p  ; was: sub_334FE
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Stage21_AsteroidAmbientSpawnReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage21_AsteroidAmbientSpawnReturn
                bsr.w   Stage21_InitializeAsteroidObject
                move.w  #$400,$E(a0)
                clr.b   $21(a0)
                move.b  #$60,$20(a0)                    ; '`'
                bset    #0,$5F(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Stage21_AsteroidAmbientMappingTable(pc,d0.w),8(a0)
                clr.w   $C(a0)
                addq.w  #1,$5A(a5)
                move.w  $5A(a5),d0
                andi.w  #7,d0
                add.w   d0,d0
                add.w   d0,d0
                btst    #0,(SharedScratchLong4).w
                bne.s   Stage21_AsteroidSelectAlternateAmbientPositions
                lea     Stage21_AsteroidAmbientPositionTableA(pc),a1
                nop
                bra.s   Stage21_AsteroidInitAmbientPosition
; ---------------------------------------------------------------------------
Stage21_AsteroidSelectAlternateAmbientPositions:        ; CODE XREF: Stage21_AsteroidFieldSpawnAmbientRock+58   j  ; was: loc_33560
                lea     Stage21_AsteroidAmbientPositionTableB(pc),a1
                nop
Stage21_AsteroidInitAmbientPosition:                    ; CODE XREF: Stage21_AsteroidFieldSpawnAmbientRock+60   j  ; was: loc_33566
                move.w  (a1,d0.w),$10(a0)
                move.w  2(a1,d0.w),$14(a0)
                move.w  #$40,$48(a0)                    ; '@'
Stage21_AsteroidAmbientSpawnReturn:                     ; CODE XREF: Stage21_AsteroidFieldSpawnAmbientRock+8   j  ; was: locret_33578
                                        ; Stage21_AsteroidFieldSpawnAmbientRock+10   j
                rts
; End of function Stage21_AsteroidFieldSpawnAmbientRock
; ---------------------------------------------------------------------------
Stage21_AsteroidAmbientMappingTable:    dc.l    Stage21_AmbientRockMappingA  ; DATA XREF: Stage21_AsteroidFieldSpawnAmbientRock+38   r  ; was: off_3357A
                dc.l    Stage21_AmbientRockMappingB
                dc.l    Stage21_AmbientRockMappingC
                dc.l    Stage21_AmbientRockMappingA
Stage21_AsteroidAmbientPositionTableA:  dc.w    $1D0, $120, $170, $170, $1D0, $B0, $D0, $170, $1D0, $120, $1D0, $B0, $170, $170, $D0, $170  ; was: word_3358A
                                        ; DATA XREF: Stage21_AsteroidFieldSpawnAmbientRock+5A   o
Stage21_AsteroidAmbientPositionTableB:  dc.w    $1D0, $B0, $D0, $80, $170, $80, $1D0, $120, $60, $B0, $D0, $170, $60, $120, $170, $170  ; was: word_335AA
                                        ; DATA XREF: Stage21_AsteroidFieldSpawnAmbientRock:Stage21_AsteroidSelectAlternateAmbientPositions   o

; Initializes delayed type-$458 debris from a destroyed asteroid
Projectile_Stage21AsteroidDebrisInit:                   ; CODE XREF: Stage21_AsteroidSpawnDestructionResult:Stage21_AsteroidSpawnDebris   p  ; was: sub_335CA
                move.w  #$458,(a0)
                move.w  #$8E00,2(a0)
                move.w  #$44C8,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                move.w  #$40,$48(a0)                    ; '@'
                rts
; End of function Projectile_Stage21AsteroidDebrisInit
; Dispatches the delayed asteroid-debris state
Projectile_Stage21AsteroidDebrisMain:                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_335EE
                move.w  4(a5),d0
                lea     Projectile_Stage21AsteroidDebrisStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_Stage21AsteroidDebrisMain
; ---------------------------------------------------------------------------
Projectile_Stage21AsteroidDebrisStates: dc.w    Projectile_Stage21AsteroidDebrisBeginDelay-*  ; DATA XREF: Projectile_Stage21AsteroidDebrisMain+4   o  ; was: off_335FA
                dc.w    Projectile_Stage21AsteroidDebrisUpdateDelay-*
                dc.w    Projectile_Stage21AsteroidDebrisDetonateNearPlayer-*
                dc.w    Projectile_Stage21AsteroidDebrisInactiveState-*

; Saves the initial Y coordinate and enters the bobbing debris delay
Projectile_Stage21AsteroidDebrisBeginDelay:             ; DATA XREF: ROM:Projectile_Stage21AsteroidDebrisStates   o  ; was: sub_33602
                move.w  $14(a5),$4A(a5)
                addq.w  #2,4(a5)
; Applies sine wave vertical offset to Y position based on frame counter
Projectile_Stage21AsteroidDebrisUpdateDelay:            ; DATA XREF: ROM:000335FC   o  ; was: loc_3360C
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #3,d0
                move.b  Projectile_Stage21AsteroidDebrisBobTable(pc,d0.w),d0
                ext.w   d0
                add.w   $4A(a5),d0
                move.w  d0,$14(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_Stage21AsteroidDebrisUpdateDelay_Return
                move.l  $4C(a5),$18(a5)
                move.l  $50(a5),$1C(a5)
                addq.w  #2,4(a5)
Projectile_Stage21AsteroidDebrisUpdateDelay_Return:     ; CODE XREF: Projectile_Stage21AsteroidDebrisBeginDelay+26   j  ; was: locret_3363A
                rts
; End of function Projectile_Stage21AsteroidDebrisBeginDelay
; ---------------------------------------------------------------------------
Projectile_Stage21AsteroidDebrisBobTable:   dc.w    $FF00, $100  ; DATA XREF: Projectile_Stage21AsteroidDebrisBeginDelay+14   r  ; was: word_3363C

; Converts debris into an explosion within 16 horizontal pixels of the player
Projectile_Stage21AsteroidDebrisDetonateNearPlayer:     ; DATA XREF: ROM:000335FE   o  ; was: sub_33640
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$10,d0
                bpl.s   Projectile_Stage21AsteroidDebrisDetonateNearPlayer_Return
                move.w  #$C8,$26(a5)
                jsr     (Effect_InitSharedExplosionFromCurrent).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
Projectile_Stage21AsteroidDebrisDetonateNearPlayer_Return:  ; CODE XREF: Projectile_Stage21AsteroidDebrisDetonateNearPlayer+A   j  ; was: locret_33660
                rts
; End of function Projectile_Stage21AsteroidDebrisDetonateNearPlayer
Projectile_Stage21AsteroidDebrisInactiveState:          ; DATA XREF: ROM:00033600   o  ; was: nullsub_76
                rts
; End of function Projectile_Stage21AsteroidDebrisInactiveState
