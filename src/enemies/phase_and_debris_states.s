Enemy_PhasePatternController:                           ; was: sub_2D020
                tst.w   4(a5)
                beq.s   Enemy_PhasePatternController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ResetPhasePattern
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ResetPhasePattern
                jsr     (RandomNumber).l
                clr.w   6(a5)
Enemy_PhasePatternController_UpdateState:               ; was: loc_2D040
                bsr.s   Enemy_DispatchPhasePatternState
                bra.w   Enemy_ApplyPhasePatternAnimationSelector
; End of function Enemy_PhasePatternController
; Dispatches the phase-pattern enemy's current state
Enemy_DispatchPhasePatternState:                        ; was: sub_2D046
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_PhasePatternStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchPhasePatternState
; ---------------------------------------------------------------------------
Enemy_PhasePatternStateOffsets: dc.w    Enemy_PhasePatternInit-*  ; was: off_2D056
                dc.w    Enemy_PhasePatternWaitState-*
                dc.w    Enemy_PhasePatternAirborneState-*
                dc.w    Enemy_PhasePattern_WaitBeforeAttack-*
                dc.w    Enemy_PhasePattern_BeginHorizontalMotion-*
                dc.w    Enemy_PhasePattern_StopHorizontalMotion-*
                dc.w    Enemy_PhasePattern_Restart-*

; Initializes the phase-pattern sprite and first wait interval
Enemy_PhasePatternInit:                                 ; was: sub_2D064
                moveq   #0,d0
                bsr.w   Enemy_SetupPhasePatternSprite
                move.w  #4,$5C(a5)
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
; Waits, and leaps when the player presses the bit-5 button
Enemy_PhasePatternWaitState:                            ; was: loc_2D07A
                subq.w  #1,$48(a5)
                beq.s   Enemy_PhasePatternWaitState_Timeout
                btst    #5,(ControllerPressedState).w
                beq.s   Enemy_PhasePatternWaitState_Return
                addq.w  #2,4(a5)
                btst    #4,$E(a5)
                bne.s   Enemy_PhasePatternWaitState_Return
                move.l  #$FFFA0000,$1C(a5)
Enemy_PhasePatternWaitState_Return:                     ; was: locret_2D09C
                                        ; Enemy_PhasePatternInit+2E   j
                rts
; ---------------------------------------------------------------------------
Enemy_PhasePatternWaitState_Timeout:                    ; was: loc_2D09E
                move.w  #$20,$48(a5)                    ; ' '
                move.w  #6,4(a5)
                move.w  #$10,$5C(a5)
                rts
; End of function Enemy_PhasePatternInit
; Applies gravity and returns the phase-pattern enemy to a surface on contact
Enemy_PhasePatternAirborneState:                        ; was: sub_2D0B2
                cmpi.l  #$80000,$1C(a5)
                bge.s   Enemy_PhasePatternAirborneState_SelectProbe
                addi.l  #$4000,$1C(a5)
Enemy_PhasePatternAirborneState_SelectProbe:            ; was: loc_2D0C4
                moveq   #0,d0
                tst.l   $1C(a5)
                bmi.s   Enemy_PhasePatternAirborneState_ProbeCeiling
                move.w  #$20,d1                         ; ' '
                bra.s   Enemy_PhasePatternAirborneState_CheckTerrain
; ---------------------------------------------------------------------------
Enemy_PhasePatternAirborneState_ProbeCeiling:           ; was: loc_2D0D2
                move.w  #$FFE4,d1
Enemy_PhasePatternAirborneState_CheckTerrain:           ; was: loc_2D0D6
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                beq.s   Enemy_PhasePatternAirborneState_Return
                move.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                tst.l   $1C(a5)
                bmi.s   Enemy_PhasePatternAirborneState_AlignCeiling
                bclr    #4,$E(a5)
                moveq   #0,d0
                move.w  #$20,d1                         ; ' '
                jsr     (Physics_AlignToTerrain).l
                rts
; ---------------------------------------------------------------------------
Enemy_PhasePatternAirborneState_AlignCeiling:           ; was: loc_2D10C
                bset    #4,$E(a5)
                moveq   #0,d0
                move.w  #$FFE4,d1
                jsr     (Physics_AlignToTerrainTop).l
Enemy_PhasePatternAirborneState_Return:                 ; was: locret_2D11E
                rts
; End of function Enemy_PhasePatternAirborneState
; Holds the landed pose, then selects animation $14 and advances
Enemy_PhasePattern_WaitBeforeAttack:                    ; was: sub_2D120
                subq.w  #1,$48(a5)
                bne.s   Enemy_PhasePattern_WaitBeforeAttack_Return
                move.w  #$14,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_PhasePattern_WaitBeforeAttack_Return:             ; was: locret_2D136
                rts
; End of function Enemy_PhasePattern_WaitBeforeAttack
; Starts a one-unit leftward drift and selects animation $1C
Enemy_PhasePattern_BeginHorizontalMotion:               ; was: sub_2D138
                subq.w  #1,$48(a5)
                bne.s   Enemy_PhasePattern_BeginHorizontalMotion_Return
                move.w  #$1C,$5C(a5)
                move.w  #$FFFF,$18(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_PhasePattern_BeginHorizontalMotion_Return:        ; was: locret_2D154
                rts
; End of function Enemy_PhasePattern_BeginHorizontalMotion
; Stops the drift and selects animation $18
Enemy_PhasePattern_StopHorizontalMotion:                ; was: sub_2D156
                subq.w  #1,$48(a5)
                bne.s   Enemy_PhasePattern_StopHorizontalMotion_Return
                clr.w   $18(a5)
                move.w  #$18,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Enemy_PhasePattern_StopHorizontalMotion_Return:         ; was: locret_2D170
                rts
; End of function Enemy_PhasePattern_StopHorizontalMotion
; Rearms the long wait and returns to the waiting state
Enemy_PhasePattern_Restart:                             ; was: sub_2D172
                subq.w  #1,$48(a5)
                bne.s   Enemy_PhasePattern_Restart_Return
                move.w  #$100,$48(a5)
                move.w  #4,$5C(a5)
                move.w  #2,4(a5)
Enemy_PhasePattern_Restart_Return:                      ; was: locret_2D18A
                rts
; End of function Enemy_PhasePattern_Restart
; Returns the object to type $290 and its initial state when the wave ends
Enemy_ResetPhasePattern:                                ; was: sub_2D18C
                                        ; Enemy_PhasePatternController+12   j
                clr.w   4(a5)
                move.w  #$290,(a5)
                move.w  #$40,$48(a5)                    ; '@'
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                clr.l   $18(a5)
                rts
; End of function Enemy_ResetPhasePattern
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
Effect_RandomParticleMappings:  dc.l    SharedCombatSpriteAnimation00  ; was: off_2D26C
                dc.l    SharedCombatSpriteAnimation01
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation01
