Enemy_InitBirdSprite:                                   ; was: sub_2DA3A
                move.w  #$6F00,2(a5)
                move.w  (BirdEnemyTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                lea     Enemy_BirdSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_InitBirdSprite
; ---------------------------------------------------------------------------
Enemy_BirdSpriteParameters: dc.w    $1806, $1100        ; was: word_2DA88

; Updates bird enemy animation pointer based on state index
Enemy_UpdateBirdAnimation:                              ; was: sub_2DA8C
                                        ; Enemy_ConvertBirdToDefeatDebris+32   j
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateBirdAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_BirdAnimationMappings(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateBirdAnimation_Return:                       ; was: locret_2DA9E
                rts
; End of function Enemy_UpdateBirdAnimation
; ---------------------------------------------------------------------------
Enemy_BirdAnimationMappings:    dc.l    Enemy_BirdAnimation00  ; was: off_2DAA0
                dc.l    Enemy_BirdAnimation01
                dc.l    Enemy_BirdAnimation02
                dc.l    Enemy_BirdAnimation03

; Updates sprite horizontal flip based on velocity
Enemy_UpdateHorizontalFlipFromVelocity:                 ; was: sub_2DAB0
                                        ; Enemy_Stage10WaspController+5C   j
                tst.l   $18(a5)
                beq.s   Enemy_UpdateHorizontalFlipFromVelocity_Return
                btst    #7,$18(a5)
                bne.s   Enemy_SetHorizontalFlip
                andi.w  #$F7FF,$E(a5)
                rts
; ---------------------------------------------------------------------------
; Sets sprite horizontal flip bit based on velocity direction
Enemy_SetHorizontalFlip:                                ; was: loc_2DAC6
                ori.w   #$800,$E(a5)
Enemy_UpdateHorizontalFlipFromVelocity_Return:          ; was: locret_2DACC
                rts
; End of function Enemy_UpdateHorizontalFlipFromVelocity
; Updates the bird state machine and converts defeated or inactive birds to debris
Enemy_BirdController:                                   ; was: sub_2DACE
                tst.w   4(a5)
                beq.s   Enemy_BirdController_DispatchAndRender
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertBirdToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertBirdToDefeatDebris
                bclr    #7,$22(a5)
                beq.s   Enemy_BirdController_UpdateState
                btst    #4,$22(a5)
                bne.w   Enemy_ConvertBirdToDefeatDebris
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Enemy_BirdController_UpdateState:                       ; was: loc_2DB1A
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Main loop for bird enemy dispatching state and updating animation
Enemy_BirdController_DispatchAndRender:                 ; was: loc_2DB24
                bsr.s   Enemy_DispatchBirdState
                bsr.w   Enemy_UpdateBirdAnimation
                bra.w   Enemy_UpdateHorizontalFlipFromVelocity
; End of function Enemy_BirdController
; Bird enemy state machine dispatcher using jump table
Enemy_DispatchBirdState:                                ; was: sub_2DB2E
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_BirdStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchBirdState
; ---------------------------------------------------------------------------
Enemy_BirdStateOffsets: dc.w    Enemy_BirdInit-*        ; was: off_2DB3E
                dc.w    Enemy_BirdBeginHorizontalEntryState-*
                dc.w    Enemy_BirdFireState-*
                dc.w    Enemy_BirdPrepareDiveState-*
                dc.w    Enemy_BirdDiveAttack-*
                dc.w    Enemy_BirdWaitState-*
                dc.w    Enemy_BirdChasePlayer-*
                dc.w    Enemy_BirdWaitTimer-*
                dc.w    Enemy_BirdAccelerateUpwardState-*
                dc.w    Enemy_BirdAccelerateDownwardState-*
                dc.w    Enemy_BirdReverseToUpwardState-*
                dc.w    Enemy_BirdAttackState-*
                dc.w    Enemy_BirdAccelerateDownwardExitState-*
                dc.w    Enemy_BirdOscillateMovement-*

; Unreachable: a bare return with no reference of any kind
Orphaned_BirdNoOpState:                                 ; was: nullsub_66
                rts
; End of function Orphaned_BirdNoOpState

; Initializes bird enemy position direction and movement state
Enemy_BirdInit:                                         ; was: sub_2DB5C
                moveq   #0,d0
                bsr.w   Enemy_InitBirdSprite
                addq.w  #2,4(a5)
                btst    #0,$5F(a5)
                bne.s   Enemy_BirdInit_PlaceAtLeftEdge
                move.w  #$1E0,$10(a5)
                ori.w   #$800,$E(a5)
                bra.s   Enemy_BirdInit_SelectInitialState
; ---------------------------------------------------------------------------
Enemy_BirdInit_PlaceAtLeftEdge:                         ; was: loc_2DB7C
                move.w  #$70,$10(a5)                    ; 'p'
                andi.w  #$F7FF,$E(a5)
Enemy_BirdInit_SelectInitialState:                      ; was: loc_2DB88
                btst    #1,$5F(a5)
                bne.s   Enemy_BirdSetWaitState
                move.w  #2,4(a5)
                cmpi.w  #$1B8,(Entity57Type).w
                bne.s   Enemy_BirdInit_Return
                move.b  #2,$25(a5)
                rts
; ---------------------------------------------------------------------------
; Sets bird enemy to waiting state with timer
Enemy_BirdSetWaitState:                                 ; was: loc_2DBA6
                move.w  #6,4(a5)
Enemy_BirdInit_Return:                                  ; was: locret_2DBAC
                rts
; End of function Enemy_BirdInit
; Starts the bird's horizontal screen entry and selects its direction
Enemy_BirdBeginHorizontalEntryState:                    ; was: sub_2DBAE
                addq.w  #2,4(a5)
                move.w  #4,$5C(a5)
                ori.w   #$8000,2(a5)
                btst    #0,$5F(a5)
                bne.s   Enemy_BirdBeginHorizontalEntryState_MoveRight
                move.l  #$FFFE0000,$18(a5)
                rts
; ---------------------------------------------------------------------------
; Sets positive horizontal entry velocity for the opposite spawn side
Enemy_BirdBeginHorizontalEntryState_MoveRight:          ; was: loc_2DBD0
                move.l  #$20000,$18(a5)
                rts
; End of function Enemy_BirdBeginHorizontalEntryState
; Fires the bird's periodic shot while this state remains active
Enemy_BirdFireState:                                    ; was: sub_2DBDA
                bsr.w   Enemy_BirdSpawnShot
                rts
; End of function Enemy_BirdFireState
; Selects the dive animation and advances to terrain-aware movement
Enemy_BirdPrepareDiveState:                             ; was: sub_2DBE0
                ori.w   #$8000,2(a5)
                move.w  #8,$5C(a5)
                move.w  #4,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_BirdPrepareDiveState
; Unreachable: would run the wall check and the lower terrain probe back to back
Orphaned_EnemyWallAndLowerTerrainCollision:
                jsr     (Physics_EntityWallCheck).l     ; was: sub_2DBF8
                jmp     Physics_CheckLowerTerrain
; End of function Orphaned_EnemyWallAndLowerTerrainCollision
; Bird dive attack with gravity and ground collision detection
Enemy_BirdDiveAttack:                                   ; was: sub_2DC04
                jsr     (Physics_EntityWallCheck).l
                move.b  7(a5),$58(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_BirdDiveAttack_ApplyGravity
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                bne.s   Enemy_BirdTransitionToWait
Enemy_BirdDiveAttack_ApplyGravity:                      ; was: loc_2DC26
                jsr     (Physics_CheckUpperTerrainWhenRising).l
                addi.l  #$4000,$1C(a5)
                cmpi.l  #$58000,$1C(a5)
                bgt.s   Enemy_BirdDiveAttack_BeginRecovery
                rts
; ---------------------------------------------------------------------------
Enemy_BirdDiveAttack_BeginRecovery:                     ; was: loc_2DC40
                move.w  #8,$5C(a5)
                addq.w  #8,4(a5)
                rts
; ---------------------------------------------------------------------------
; Transitions bird to waiting state with hover movement
Enemy_BirdTransitionToWait:                             ; was: loc_2DC4C
                clr.l   $18(a5)
                move.w  #$C,$5C(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_BirdDiveAttack
; Bird waiting state with timer countdown before movement
Enemy_BirdWaitState:                                    ; was: sub_2DC62
                move.w  #$C,$5C(a5)
                subq.w  #1,$48(a5)
                bne.s   Enemy_BirdWaitState_Return
                subq.w  #1,$4A(a5)
                beq.s   Enemy_BirdWaitState_BeginChase
                addq.w  #2,4(a5)
Enemy_BirdWaitState_Return:                             ; was: locret_2DC78
                rts
; ---------------------------------------------------------------------------
Enemy_BirdWaitState_BeginChase:                         ; was: loc_2DC7A
                move.w  #$C,$5C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #4,4(a5)
                rts
; End of function Enemy_BirdWaitState
; Bird chases player calculating direction and dive distance
Enemy_BirdChasePlayer:                                  ; was: sub_2DC8C
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Enemy_BirdChasePlayer_MoveRight
                move.l  #$FFFE0000,$18(a5)
                bra.s   Enemy_BirdChasePlayer_SelectVerticalMotion
; ---------------------------------------------------------------------------
Enemy_BirdChasePlayer_MoveRight:                        ; was: loc_2DCA0
                move.l  #$20000,$18(a5)
Enemy_BirdChasePlayer_SelectVerticalMotion:             ; was: loc_2DCA8
                cmpi.w  #$80,d0
                bcc.s   Enemy_BirdChasePlayer_ResetApproach
                move.w  #8,$5C(a5)
                move.l  #$FFFA8000,$1C(a5)
                addq.w  #6,4(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_BirdChasePlayer_ResetApproach:                    ; was: loc_2DCC2
                subq.w  #4,4(a5)
                tst.b   $58(a5)
                beq.s   Enemy_BirdChasePlayer_UseShallowAscent
                move.w  #8,$5C(a5)
                move.l  #$FFFB0000,$1C(a5)
                bra.s   Enemy_BirdChasePlayer_Return
; ---------------------------------------------------------------------------
Enemy_BirdChasePlayer_UseShallowAscent:                 ; was: loc_2DCDC
                move.w  #$10,$5C(a5)
                move.l  #$FFFD8000,$1C(a5)
Enemy_BirdChasePlayer_Return:                           ; was: locret_2DCEA
                rts
; End of function Enemy_BirdChasePlayer
; Bird enemy wait state timer countdown before state transition
Enemy_BirdWaitTimer:                                    ; was: sub_2DCEC
                subq.w  #1,$48(a5)
                bpl.s   Enemy_BirdWaitTimer_Return
                move.w  #4,$4A(a5)
                subq.w  #2,4(a5)
Enemy_BirdWaitTimer_Return:                             ; was: locret_2DCFC
                rts
; End of function Enemy_BirdWaitTimer
; Accelerates upward until reaching the negative vertical-speed threshold
Enemy_BirdAccelerateUpwardState:                        ; was: sub_2DCFE
                addi.l  #-$4000,$1C(a5)
                cmpi.l  #$FFFA8000,$1C(a5)
                bgt.s   Enemy_BirdAccelerateUpwardState_Return
                addq.w  #2,4(a5)
Enemy_BirdAccelerateUpwardState_Return:                 ; was: locret_2DD14
                rts
; End of function Enemy_BirdAccelerateUpwardState
; Accelerates downward until reaching the positive vertical-speed threshold
Enemy_BirdAccelerateDownwardState:                      ; was: sub_2DD16
                addi.l  #$4000,$1C(a5)
                cmpi.l  #$28000,$1C(a5)
                blt.s   Enemy_BirdAccelerateDownwardState_Return
                addq.w  #2,4(a5)
Enemy_BirdAccelerateDownwardState_Return:               ; was: locret_2DD2C
                rts
; End of function Enemy_BirdAccelerateDownwardState
; Reverses vertical motion upward, then starts the attack timer
Enemy_BirdReverseToUpwardState:                         ; was: sub_2DD2E
                addi.l  #-$4000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bgt.s   Enemy_BirdReverseToUpwardState_Return
                move.w  #$100,$48(a5)
                move.w  #4,$5C(a5)
                addq.w  #2,4(a5)
Enemy_BirdReverseToUpwardState_Return:                  ; was: locret_2DD50
                rts
; End of function Enemy_BirdReverseToUpwardState
; Bird attack state with AI movement and projectile firing
Enemy_BirdAttackState:                                  ; was: sub_2DD52
                bsr.w   Enemy_BirdAITracking
                bsr.w   Enemy_BirdSpawnShot
                subq.w  #1,$48(a5)
                bne.s   Enemy_BirdAttackState_Return
                move.w  #4,$5C(a5)
                addq.w  #2,4(a5)
Enemy_BirdAttackState_Return:                           ; was: locret_2DD6A
                rts
; End of function Enemy_BirdAttackState
; Accelerates downward before entering the oscillating movement state
Enemy_BirdAccelerateDownwardExitState:                  ; was: sub_2DD6C
                addi.l  #$4000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                blt.s   Enemy_BirdAccelerateDownwardExitState_Return
                addq.w  #2,4(a5)
Enemy_BirdAccelerateDownwardExitState_Return:           ; was: locret_2DD82
                rts
; End of function Enemy_BirdAccelerateDownwardExitState
; Bird oscillates velocity values for horizontal and vertical movement
Enemy_BirdOscillateMovement:                            ; was: sub_2DD84
                btst    #7,$1C(a5)
                bne.s   Enemy_BirdOscillateMovement_UpdateHorizontal
                addi.l  #-$2000,$1C(a5)
Enemy_BirdOscillateMovement_UpdateHorizontal:           ; was: loc_2DD94
                btst    #7,$18(a5)
                bne.s   Enemy_BirdOscillateMovement_AccelerateLeft
                addi.l  #$800,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_BirdOscillateMovement_AccelerateLeft:             ; was: loc_2DDA6
                addi.l  #-$800,$18(a5)
                rts
; End of function Enemy_BirdOscillateMovement
; Bird AI tracks player position with velocity adjustments and randomization
Enemy_BirdAITracking:                                   ; was: sub_2DDB0
                move.w  (FrameCounter).w,d7
                andi.w  #$1F,d7
                bne.s   Enemy_BirdAITracking_UpdateTarget
                move.b  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                subi.w  #$40,d0                         ; '@'
                move.w  d0,$4C(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                move.w  d0,$4E(a5)
Enemy_BirdAITracking_UpdateTarget:                      ; was: loc_2DDDA
                move.w  (PlayerCenterX).w,d0
                add.w   $4C(a5),d0
                move.w  (PlayerCenterY).w,d1
                subi.w  #$60,d1                         ; '`'
                add.w   $4E(a5),d1
                sub.w   $10(a5),d0
                beq.s   Enemy_BirdAITracking_UpdateVertical
                tst.w   d0
                bpl.s   Enemy_BirdAITracking_AccelerateRight
                subi.l  #$2000,$18(a5)
                cmpi.l  #$FFFE0000,$18(a5)
                bge.s   Enemy_BirdAITracking_UpdateVertical
                move.l  #$FFFE0000,$18(a5)
                bra.s   Enemy_BirdAITracking_UpdateVertical
; ---------------------------------------------------------------------------
Enemy_BirdAITracking_AccelerateRight:                   ; was: loc_2DE14
                addi.l  #$2000,$18(a5)
                cmpi.l  #$20000,$18(a5)
                ble.s   Enemy_BirdAITracking_UpdateVertical
                move.l  #$20000,$18(a5)
Enemy_BirdAITracking_UpdateVertical:                    ; was: loc_2DE2E
                                        ; Enemy_BirdAITracking+58   j
                sub.w   $14(a5),d1
                beq.s   Enemy_BirdAITracking_Return
                tst.w   d1
                bpl.s   Enemy_BirdAITracking_AccelerateDown
                subi.l  #$4000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bge.s   Enemy_BirdAITracking_Return
                move.l  #$FFFE0000,$1C(a5)
                bra.s   Enemy_BirdAITracking_Return
; ---------------------------------------------------------------------------
Enemy_BirdAITracking_AccelerateDown:                    ; was: loc_2DE54
                addi.l  #$4000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                ble.s   Enemy_BirdAITracking_Return
                move.l  #$20000,$1C(a5)
Enemy_BirdAITracking_Return:                            ; was: locret_2DE6E
                                        ; Enemy_BirdAITracking+98   j
                rts
; End of function Enemy_BirdAITracking
; Spawns a falling bird shot in the current horizontal direction
Enemy_BirdSpawnShot:                                    ; was: sub_2DE70
                                        ; Enemy_BirdAttackState+4   p
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.s   Enemy_BirdSpawnShot_Return
                jsr     (Projectile_FindFreeSlotForward).l
                move.w  #$2BC,(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.w  $14(a5),$14(a0)
                addi.w  #4,$14(a0)
                move.w  $10(a5),$10(a0)
                btst    #7,$18(a5)
                beq.s   Enemy_BirdSpawnShot_MoveLeft
                move.l  #$2000,$18(a0)
                addi.w  #$10,$10(a0)
                rts
; ---------------------------------------------------------------------------
Enemy_BirdSpawnShot_MoveLeft:                           ; was: loc_2DEB8
                move.l  #$FFFFE000,$18(a0)
                addi.w  #-$10,$10(a0)
Enemy_BirdSpawnShot_Return:                             ; was: locret_2DEC6
                rts
; End of function Enemy_BirdSpawnShot
; Converts the bird to defeat debris with reversed horizontal and upward velocity
Enemy_ConvertBirdToDefeatDebris:                        ; was: sub_2DEC8
                                        ; Enemy_BirdController+12   j
                clr.w   4(a5)
                move.w  #$1DC,(a5)
                move.l  $18(a5),d0
                neg.l   d0
                move.l  d0,$18(a5)
                move.l  #$FFFD8000,$1C(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $23(a5)
                move.w  #4,$4A(a5)
                move.w  #8,$5C(a5)
                bra.w   Enemy_UpdateBirdAnimation
; End of function Enemy_ConvertBirdToDefeatDebris
; Updates falling bird debris, emits particles, then drops a pickup unless the yacht is active
Enemy_UpdateBirdDefeatDebris:                           ; was: sub_2DEFE
                bsr.w   Enemy_UpdateBlinkVisibility
                addi.l  #$2000,$1C(a5)
                tst.w   4(a5)
                bne.s   Enemy_UpdateBirdDefeatDebris_EmitParticles
                tst.w   $1C(a5)
                bmi.s   Enemy_UpdateBirdDefeatDebris_EmitParticles
                addq.w  #2,4(a5)
Enemy_UpdateBirdDefeatDebris_EmitParticles:             ; was: loc_2DF1A
                                        ; Enemy_UpdateBirdDefeatDebris+16   j
                move.w  (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Enemy_UpdateBirdDefeatDebris_Return
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_UpdateBirdDefeatDebris_Return
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                jsr     (Sprite_InitType160).l
                subq.w  #1,$4A(a5)
                bne.s   Enemy_UpdateBirdDefeatDebris_Return
                moveq   #2,d0
                moveq   #4,d1
                movea.l #SharedCombatSpriteAnimation00,a1
                jsr     (Effect_SpawnRadialParticlePattern).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                cmpi.w  #$1B8,(Entity57Type).w
                beq.s   Enemy_UpdateBirdDefeatDebris_HideInsteadOfPickup
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateBirdDefeatDebris_HideInsteadOfPickup:       ; was: loc_2DF76
                bset    #4,2(a5)
Enemy_UpdateBirdDefeatDebris_Return:                    ; was: locret_2DF7C
                                        ; Enemy_UpdateBirdDefeatDebris+2C   j
                rts
; End of function Enemy_UpdateBirdDefeatDebris
