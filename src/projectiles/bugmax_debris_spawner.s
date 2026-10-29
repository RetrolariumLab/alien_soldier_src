; Initializes a Bugmax debris spawner in the current object record
Projectile_InitBugmaxDebrisSpawnerFromCurrentObject:
                movea.w a5,a0                           ; was: sub_2C254
; Initializes a type-$348 spawner with lifetime D0, horizontal span D1,
; vertical separation D2, and a randomized 0-31-frame initial delay
Projectile_InitBugmaxDebrisSpawner:                     ; was: loc_2C256
                move.w  #$348,(a0)
                move.w  #$F40,2(a0)
                move.w  d0,$4A(a0)
                move.w  d1,$4C(a0)
                move.w  d2,$4E(a0)
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                move.w  d0,$48(a0)
                rts
; End of function Projectile_InitBugmaxDebrisSpawnerFromCurrentObject
; Counts down the spawner lifetime and dispatches its three-state emission loop
Projectile_BugmaxDebrisSpawner:                         ; was: sub_2C280
                subq.w  #1,$4A(a5)
                bpl.s   Projectile_BugmaxDebrisSpawner_DispatchState
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
; Dispatches the debris spawner's current state
Projectile_BugmaxDebrisSpawner_DispatchState:           ; was: loc_2C28E
                move.w  4(a5),d0
                lea     Projectile_BugmaxDebrisSpawnerStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_BugmaxDebrisSpawner
; ---------------------------------------------------------------------------
Projectile_BugmaxDebrisSpawnerStateHandlers:    dc.w    Projectile_BugmaxDebrisSpawner_WaitInitialRandomDelay-*  ; was: off_2C29A
                dc.w    Projectile_BugmaxDebrisSpawner_TrySpawnParticle-*
                dc.w    Projectile_BugmaxDebrisSpawner_WaitSpawnInterval-*

; Waits for the initial randomized delay
Projectile_BugmaxDebrisSpawner_WaitInitialRandomDelay:  ; was: sub_2C2A0
                subq.w  #1,$48(a5)
                bpl.s   Projectile_BugmaxDebrisSpawner_WaitInitialRandomDelay_Return
                addq.w  #2,4(a5)
Projectile_BugmaxDebrisSpawner_WaitInitialRandomDelay_Return:  ; was: locret_2C2AA
                rts
; End of function Projectile_BugmaxDebrisSpawner_WaitInitialRandomDelay
; Tries to spawn one debris particle and starts the eight-frame interval
Projectile_BugmaxDebrisSpawner_TrySpawnParticle:        ; was: sub_2C2AC
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_BugmaxDebrisSpawner_SpawnAttemptReturn
                jsr     (RandomNumber).l
                btst    #0,(RandomNumberState).w
                beq.s   Projectile_BugmaxDebrisSpawner_InitializeParticle
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_BugmaxDebrisSpawner_InitializeParticle:      ; was: loc_2C2CC
                jsr     (Projectile_InitType88).l
                btst    #0,(RandomNumberState+2).w
                beq.s   Projectile_BugmaxDebrisSpawner_UseAnimation05
                move.l  #Effect_SpriteAnimation00,8(a0)
                bra.s   Projectile_BugmaxDebrisSpawner_PositionParticleInConfiguredSpread
; ---------------------------------------------------------------------------
Projectile_BugmaxDebrisSpawner_UseAnimation05:          ; was: loc_2C2E4
                move.l  #Effect_SpriteAnimation05,8(a0)
; Selects X within the centered D1 span and Y at either half of D2 from center
Projectile_BugmaxDebrisSpawner_PositionParticleInConfiguredSpread:  ; was: loc_2C2EC
                move.b  (RandomNumberState).w,d0
                move.w  $4C(a5),d1
                move.w  d1,d2
                subq.w  #1,d1
                and.w   d1,d0
                lsr.w   #1,d2
                sub.w   d2,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                move.w  $4E(a5),d1
                move.w  d1,d2
                subq.w  #1,d1
                and.w   d2,d0
                lsr.w   #1,d2
                sub.w   d2,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.w  #8,$50(a5)
                addq.w  #2,4(a5)
Projectile_BugmaxDebrisSpawner_SpawnAttemptReturn:      ; was: locret_2C32A
                rts
; End of function Projectile_BugmaxDebrisSpawner_TrySpawnParticle
; Counts down the interval before returning to the spawn-attempt state
Projectile_BugmaxDebrisSpawner_WaitSpawnInterval:       ; was: sub_2C32C
                subq.w  #1,$50(a5)
                bne.s   Projectile_BugmaxDebrisSpawner_WaitSpawnInterval_Return
                subq.w  #2,4(a5)
Projectile_BugmaxDebrisSpawner_WaitSpawnInterval_Return:  ; was: locret_2C336
                rts
; End of function Projectile_BugmaxDebrisSpawner_WaitSpawnInterval
Effect_ExplosionUpdateReturn:                           ; was: nullsub_61
                                        ; Effect_SpawnExplosionB+6   j
                rts
; End of function Effect_ExplosionUpdateReturn
