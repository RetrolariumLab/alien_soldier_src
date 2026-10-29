; Orphaned rising-shot pair controller with no static caller or ROM pointer
Orphaned_RisingShotPairControllerMain:                  ; was: sub_337E4
                move.w  4(a5),d0
                lea     Orphaned_RisingShotPairControllerStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Orphaned_RisingShotPairControllerMain
; ---------------------------------------------------------------------------
Orphaned_RisingShotPairControllerStates:    dc.w    Orphaned_RisingShotPairInitDelay-*  ; was: off_337F0
                dc.w    Orphaned_RisingShotPairWaitAndFire-*
                dc.w    Orphaned_RisingShotPairAllocate-*
                dc.w    Orphaned_RisingShotPairLaunch-*
                dc.w    Orphaned_RisingShotPairWaitForCycle-*
                dc.w    Orphaned_RisingShotPairFirePeriod-*

; Initializes the pair controller's opening delay
Orphaned_RisingShotPairInitDelay:                       ; was: sub_337FC
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
; Waits through the opening period while emitting falling shots
Orphaned_RisingShotPairWaitAndFire:                     ; was: loc_33806
                bsr.w   Orphaned_RisingShotPairFireFallingShot
                subq.w  #1,$48(a5)
                bne.s   Orphaned_RisingShotPairWaitReturn
                move.w  #8,$4A(a5)
                addq.w  #2,4(a5)
Orphaned_RisingShotPairWaitReturn:                      ; was: locret_3381A
                rts
; End of function Orphaned_RisingShotPairInitDelay
; Allocates and stores two empty slots for rising-shot members
Orphaned_RisingShotPairAllocate:                        ; was: sub_3381C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Orphaned_RisingShotPairAllocateReturn
                move.w  #$10,(a0)
                move.w  a0,$5C(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Orphaned_RisingShotPairHandleAllocationFailure
                move.w  #$10,(a0)
                move.w  a0,$5E(a5)
                addq.w  #2,4(a5)
Orphaned_RisingShotPairAllocateReturn:                  ; was: locret_33840
                rts
; ---------------------------------------------------------------------------
Orphaned_RisingShotPairHandleAllocationFailure:         ; was: loc_33842
                movea.w $5C(a5),a0
                move.w  #$1000,2(a0)
                subq.w  #4,4(a5)
                rts
; End of function Orphaned_RisingShotPairAllocate
; Launches the pair from a random table-selected X coordinate
Orphaned_RisingShotPairLaunch:                          ; was: sub_33852
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                add.w   d0,d0
                move.w  Orphaned_RisingShotPairXPositions(pc,d0.w),d0
                move.w  #$170,d1
                movea.w $5C(a5),a0
                move.l  #$FFFF0000,d2
                move.l  #$FFFFF000,d3
                bsr.w   Projectile_InitRisingShotWaveMember
                addi.w  #$30,d0                         ; '0'
                movea.w $5E(a5),a0
                move.l  #$FFFF0000,d2
                move.l  #$FFFFF000,d3
                bsr.w   Projectile_InitRisingShotWaveMember
                move.w  #$30,$48(a5)                    ; '0'
                addq.w  #2,4(a5)
                rts
; End of function Orphaned_RisingShotPairLaunch
; ---------------------------------------------------------------------------
Orphaned_RisingShotPairXPositions:  dc.w    $90, $A0, $B0, $C0, $D0, $E0, $F0, $100, $110, $120, $130, $140, $150, $160, $170, $180  ; was: word_3389C

; Waits between pair cycles and counts down the remaining cycles
Orphaned_RisingShotPairWaitForCycle:                    ; was: sub_338BC
                subq.w  #1,$48(a5)
                bne.s   Orphaned_RisingShotPairCycleWaitReturn
                subq.w  #1,$4A(a5)
                beq.s   Orphaned_RisingShotPairBeginFirePeriod
                subq.w  #4,4(a5)
Orphaned_RisingShotPairCycleWaitReturn:                 ; was: locret_338CC
                rts
; ---------------------------------------------------------------------------
Orphaned_RisingShotPairBeginFirePeriod:                 ; was: loc_338CE
                move.w  #$200,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Orphaned_RisingShotPairWaitForCycle
; Emits Missiray shots for a fixed period before restarting the sequence
Orphaned_RisingShotPairFirePeriod:                      ; was: sub_338DA
                bsr.w   Orphaned_RisingShotPairFireMissirayShot
                subq.w  #1,$48(a5)
                bne.s   Orphaned_RisingShotPairFirePeriodReturn
                move.w  #0,4(a5)
Orphaned_RisingShotPairFirePeriodReturn:                ; was: locret_338EA
                rts
; End of function Orphaned_RisingShotPairFirePeriod
; Periodically creates a type-$3C4 Missiray falling shot
Orphaned_RisingShotPairFireFallingShot:                 ; was: sub_338EC
                move.w  (FrameCounter).w,d7
                andi.w  #$3F,d7                         ; '?'
                bne.s   Orphaned_RisingShotPairFallingShotReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Orphaned_RisingShotPairFallingShotReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                addi.w  #$120,d0
                move.w  #$120,d1
                move.l  #$FFFF0000,d2
                move.l  #$FFFFF000,d3
                bsr.w   Projectile_InitMissirayFallingShot
Orphaned_RisingShotPairFallingShotReturn:               ; was: locret_33922
                                        ; Orphaned_RisingShotPairFireFallingShot+10   j
                rts
; End of function Orphaned_RisingShotPairFireFallingShot
; Periodically creates a type-$3CC Missiray shot
Orphaned_RisingShotPairFireMissirayShot:                ; was: sub_33924
                move.w  (FrameCounter).w,d7
                andi.w  #$3F,d7                         ; '?'
                bne.s   Orphaned_RisingShotPairMissirayShotReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Orphaned_RisingShotPairMissirayShotReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                addi.w  #$120,d0
                move.w  #$120,d1
                move.l  #$FFFF0000,d2
                bsr.w   Projectile_InitMissirayBullet
Orphaned_RisingShotPairMissirayShotReturn:              ; was: locret_33954
                                        ; Orphaned_RisingShotPairFireMissirayShot+10   j
                rts
; End of function Orphaned_RisingShotPairFireMissirayShot
