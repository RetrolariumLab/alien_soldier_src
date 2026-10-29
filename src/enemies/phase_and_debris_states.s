Enemy_EyePodController:                                 ; was: sub_2D020
                tst.w   4(a5)
                beq.s   Enemy_EyePodController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ResetEyePod
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ResetEyePod
                jsr     (RandomNumber).l
                clr.w   6(a5)
Enemy_EyePodController_UpdateState:                     ; was: loc_2D040
                bsr.s   Enemy_DispatchEyePodState
                bra.w   Enemy_ApplyEyePodAnimationSelector
; End of function Enemy_EyePodController
; Dispatches the phase-pattern enemy's current state
Enemy_DispatchEyePodState:                              ; was: sub_2D046
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_EyePodStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchEyePodState
; ---------------------------------------------------------------------------
Enemy_EyePodStateOffsets:   dc.w    Enemy_EyePodInit-*  ; was: off_2D056
                dc.w    Enemy_EyePodWaitState-*
                dc.w    Enemy_EyePodAirborneState-*
                dc.w    Enemy_EyePod_WaitBeforeAttack-*
                dc.w    Enemy_EyePod_BeginHorizontalMotion-*
                dc.w    Enemy_EyePod_StopHorizontalMotion-*
                dc.w    Enemy_EyePod_Restart-*

; Initializes the phase-pattern sprite and first wait interval
Enemy_EyePodInit:                                       ; was: sub_2D064
                moveq   #0,d0
                bsr.w   Enemy_SetupEyePodSprite
                move.w  #4,$5C(a5)
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
; Waits, and leaps when the player presses the bit-5 button
Enemy_EyePodWaitState:                                  ; was: loc_2D07A
                subq.w  #1,$48(a5)
                beq.s   Enemy_EyePodWaitState_Timeout
                btst    #5,(ControllerPressedState).w
                beq.s   Enemy_EyePodWaitState_Return
                addq.w  #2,4(a5)
                btst    #4,$E(a5)
                bne.s   Enemy_EyePodWaitState_Return
                move.l  #$FFFA0000,$1C(a5)
Enemy_EyePodWaitState_Return:                           ; was: locret_2D09C
                                        ; Enemy_EyePodInit+2E   j
                rts
; ---------------------------------------------------------------------------
Enemy_EyePodWaitState_Timeout:                          ; was: loc_2D09E
                move.w  #$20,$48(a5)                    ; ' '
                move.w  #6,4(a5)
                move.w  #$10,$5C(a5)
                rts
; End of function Enemy_EyePodInit
; Applies gravity and returns the phase-pattern enemy to a surface on contact
Enemy_EyePodAirborneState:                              ; was: sub_2D0B2
                cmpi.l  #$80000,$1C(a5)
                bge.s   Enemy_EyePodAirborneState_SelectProbe
                addi.l  #$4000,$1C(a5)
Enemy_EyePodAirborneState_SelectProbe:                  ; was: loc_2D0C4
                moveq   #0,d0
                tst.l   $1C(a5)
                bmi.s   Enemy_EyePodAirborneState_ProbeCeiling
                move.w  #$20,d1                         ; ' '
                bra.s   Enemy_EyePodAirborneState_CheckTerrain
; ---------------------------------------------------------------------------
Enemy_EyePodAirborneState_ProbeCeiling:                 ; was: loc_2D0D2
                move.w  #$FFE4,d1
Enemy_EyePodAirborneState_CheckTerrain:                 ; was: loc_2D0D6
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                beq.s   Enemy_EyePodAirborneState_Return
                move.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                tst.l   $1C(a5)
                bmi.s   Enemy_EyePodAirborneState_AlignCeiling
                bclr    #4,$E(a5)
                moveq   #0,d0
                move.w  #$20,d1                         ; ' '
                jsr     (Physics_AlignToTerrain).l
                rts
; ---------------------------------------------------------------------------
Enemy_EyePodAirborneState_AlignCeiling:                 ; was: loc_2D10C
                bset    #4,$E(a5)
                moveq   #0,d0
                move.w  #$FFE4,d1
                jsr     (Physics_AlignToTerrainTop).l
Enemy_EyePodAirborneState_Return:                       ; was: locret_2D11E
                rts
; End of function Enemy_EyePodAirborneState
; Holds the landed pose, then selects animation $14 and advances
Enemy_EyePod_WaitBeforeAttack:                          ; was: sub_2D120
                subq.w  #1,$48(a5)
                bne.s   Enemy_EyePod_WaitBeforeAttack_Return
                move.w  #$14,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_EyePod_WaitBeforeAttack_Return:                   ; was: locret_2D136
                rts
; End of function Enemy_EyePod_WaitBeforeAttack
; Starts a one-unit leftward drift and selects animation $1C
Enemy_EyePod_BeginHorizontalMotion:                     ; was: sub_2D138
                subq.w  #1,$48(a5)
                bne.s   Enemy_EyePod_BeginHorizontalMotion_Return
                move.w  #$1C,$5C(a5)
                move.w  #$FFFF,$18(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_EyePod_BeginHorizontalMotion_Return:              ; was: locret_2D154
                rts
; End of function Enemy_EyePod_BeginHorizontalMotion
; Stops the drift and selects animation $18
Enemy_EyePod_StopHorizontalMotion:                      ; was: sub_2D156
                subq.w  #1,$48(a5)
                bne.s   Enemy_EyePod_StopHorizontalMotion_Return
                clr.w   $18(a5)
                move.w  #$18,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_EyePod_StopHorizontalMotion_Return:               ; was: locret_2D170
                rts
; End of function Enemy_EyePod_StopHorizontalMotion
; Rearms the long wait and returns to the waiting state
Enemy_EyePod_Restart:                                   ; was: sub_2D172
                subq.w  #1,$48(a5)
                bne.s   Enemy_EyePod_Restart_Return
                move.w  #$100,$48(a5)
                move.w  #4,$5C(a5)
                move.w  #2,4(a5)
Enemy_EyePod_Restart_Return:                            ; was: locret_2D18A
                rts
; End of function Enemy_EyePod_Restart
; Returns the object to type $290 and its initial state when the wave ends
Enemy_ResetEyePod:                                      ; was: sub_2D18C
                                        ; Enemy_EyePodController+12   j
                clr.w   4(a5)
                move.w  #$290,(a5)
                move.w  #$40,$48(a5)                    ; '@'
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                clr.l   $18(a5)
                rts
; End of function Enemy_ResetEyePod
; Updates the bouncing defeat-debris object and emits randomized child particles
Enemy_UpdateBouncingDebrisSpawner:                      ; was: sub_2D1AC
                bsr.w   Enemy_UpdateBlinkVisibility
                tst.l   $1C(a5)
                beq.s   Enemy_UpdateBouncingDebrisSpawner_SpawnParticle
                cmpi.l  #$80000,$1C(a5)
                bge.s   Enemy_UpdateBouncingDebrisSpawner_ApplyGravity
                addi.l  #$4000,$1C(a5)
Enemy_UpdateBouncingDebrisSpawner_ApplyGravity:         ; was: loc_2D1C8
                moveq   #0,d0
                move.w  #$20,d1                         ; ' '
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                beq.s   Enemy_UpdateBouncingDebrisSpawner_SpawnParticle
                bclr    #4,$E(a5)
                moveq   #0,d0
                move.w  #$20,d1                         ; ' '
                jsr     (Physics_AlignToTerrain).l
Enemy_UpdateBouncingDebrisSpawner_SpawnParticle:        ; was: loc_2D1EA
                                        ; Enemy_UpdateBouncingDebrisSpawner+2A   j
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_UpdateBouncingDebrisSpawner_Return
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Enemy_UpdateBouncingDebrisSpawner_InitParticle
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
Enemy_UpdateBouncingDebrisSpawner_InitParticle:         ; was: loc_2D206
                bsr.s   Effect_SetRandomParticleMapping
                jsr     (Projectile_InitType88).l
                move.b  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                move.w  $10(a5),$10(a0)
                add.w   d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                move.w  $14(a5),$14(a0)
                add.w   d0,$14(a0)
                move.w  #$FFFE,$1C(a0)
                subq.w  #1,$48(a5)
                bne.s   Enemy_UpdateBouncingDebrisSpawner_Return
                jsr     (Effect_SpawnExplosionB).l
                moveq   #3,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateBouncingDebrisSpawner_Return:               ; was: locret_2D254
                                        ; Enemy_UpdateBouncingDebrisSpawner+98   j
                rts
; End of function Enemy_UpdateBouncingDebrisSpawner
; Unreachable entry that would aim the random-mapping helper at the current object
Orphaned_SetRandomParticleMappingForSelf:
                movea.w a5,a0                           ; was: sub_2D256
; End of function Orphaned_SetRandomParticleMappingForSelf
; Sets random animation pointer from 4-entry table based on random number bits 0-1
Effect_SetRandomParticleMapping:                        ; was: sub_2D258
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Effect_RandomParticleMappings(pc,d0.w),8(a0)
                rts
; End of function Effect_SetRandomParticleMapping
; ---------------------------------------------------------------------------
Effect_RandomParticleMappings:  dc.l    Effect_SpriteAnimation00  ; was: off_2D26C
                dc.l    Effect_SpriteAnimation01
                dc.l    Effect_SpriteAnimation02
                dc.l    Effect_SpriteAnimation01
