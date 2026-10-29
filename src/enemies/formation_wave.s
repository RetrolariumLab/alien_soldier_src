; Type-$3B4 formation-wave controller and members
Enemy_FormationWaveMain:                                ; was: sub_32EE0
                lea     (SharedSceneDataBuffer).w,a4
                bsr.w   Enemy_FormationWaveDispatchState
                subq.w  #1,$5A(a5)
                beq.s   Enemy_FormationWaveFinishUpdate
                btst    #7,$22(a5)
                bne.s   Enemy_FormationWaveFinishUpdate
                tst.w   $24(a5)
                bmi.s   Enemy_FormationWavePrepareAimedShot
                tst.w   (StageSpawnCountdown).w
                bmi.w   Enemy_FormationWaveReturn
Enemy_FormationWavePrepareAimedShot:                    ; was: loc_32F04
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_FormationWaveFinishUpdate
                moveq   #9,d7
                moveq   #0,d0
                moveq   #1,d1
                move.w  (GlobalSpritePriorityBit).w,d2
                jsr     (Projectile_InitializeTwoSpeedShot).l
Enemy_FormationWaveFinishUpdate:                        ; was: loc_32F24
                                        ; Enemy_FormationWaveMain+14   j
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Enemy_FormationWaveMain
; Dispatches a formation member through its motion-state table
Enemy_FormationWaveDispatchState:                       ; was: sub_32F32
                movea.w 4(a5),a0
                lea     Enemy_FormationWaveStates(pc,a0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_FormationWaveDispatchState
; ---------------------------------------------------------------------------
Enemy_FormationWaveStates:  dc.w    Enemy_FormationWaveSpawnMembers-*  ; was: off_32F3E
                dc.w    Enemy_FormationWaveBeginStraightLeftMotion-*
                dc.w    Enemy_FormationWaveBeginVerticalOscillation-*
                dc.w    Enemy_FormationWaveUpdateVerticalOscillation-*
                dc.w    Enemy_FormationWaveDeactivatePastLeftBoundary-*
                dc.w    Enemy_FormationWaveBeginPositiveAcceleratedPath-*
                dc.w    Enemy_FormationWaveUpdateAcceleratedPath-*
                dc.w    Enemy_FormationWaveBeginNegativeAcceleratedPath-*
                dc.w    Enemy_FormationWaveReturn-*
Enemy_FormationWaveInitialStateTable:   dc.w    2, 4, $A, $E, 4, 4, 4, 4  ; was: word_32F50

; Spawns the remaining members of a formation wave
Enemy_FormationWaveSpawnMembers:                        ; was: sub_32F60
                lea     (a5),a0
                move.w  $5E(a5),d7
                andi.w  #$FF,d7
                move.w  Enemy_FormationWaveInitialStateTable(pc,d7.w),d5
                move.b  $5E(a5),d7
                moveq   #0,d6
Enemy_FormationWaveInitNextMember:                      ; was: loc_32F74
                bsr.w   Enemy_FormationWaveInitMember
                jsr     (Projectile_FindFreeSlotForward).l
                dbne    d7,Enemy_FormationWaveInitNextMember
                rts
; End of function Enemy_FormationWaveSpawnMembers
; Initializes one type-$3B4 formation member
Enemy_FormationWaveInitMember:                          ; was: sub_32F84
                move.w  $5E(a5),$5E(a0)
                move.w  #$200,$5A(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                add.w   d6,$10(a0)
                move.w  d6,$5C(a0)
                addi.w  #$20,d6                         ; ' '
                move.w  d5,4(a0)
                move.w  #$3B4,(a0)
                move.w  #$ED00,2(a0)
                move.w  #$400,$E(a0)
                move.l  #Enemy_FormationWaveSpriteAnimation,8(a0)
                move.b  #$C0,$21(a0)
                move.w  #1,$24(a0)
                move.w  #$32,$26(a0)                    ; '2'
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.b  #$40,$20(a0)                    ; '@'
                move.b  #8,$23(a0)
                rts
; End of function Enemy_FormationWaveInitMember
; Starts a formation member moving straight left, then selects the boundary check
Enemy_FormationWaveBeginStraightLeftMotion:             ; was: sub_32FF4
                move.l  #$FFFEC000,$18(a5)
                move.w  #8,4(a5)
                rts
; End of function Enemy_FormationWaveBeginStraightLeftMotion
; Marks a formation member for removal after it crosses the left boundary
Enemy_FormationWaveDeactivatePastLeftBoundary:          ; was: sub_33004
                                        ; Enemy_FormationWaveBeginPositiveAcceleratedPath+24   j
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcc.w   Enemy_FormationWaveReturn
                ori.w   #$1000,2(a5)
                rts
; End of function Enemy_FormationWaveDeactivatePastLeftBoundary
; Delays by formation offset, then starts the vertical oscillation path
Enemy_FormationWaveBeginVerticalOscillation:            ; was: sub_33016
                move.l  #$FFFF0000,$18(a5)
                subq.w  #1,$5C(a5)
                bpl.w   Enemy_FormationWaveReturn
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$800,$5C(a5)
                addq.w  #2,4(a5)
; Applies vertical acceleration and reverses it at speed magnitude $10000
Enemy_FormationWaveUpdateVerticalOscillation:           ; was: loc_3303A
                move.l  $5C(a5),d0
                add.l   d0,$1C(a5)
                move.l  $1C(a5),d0
                bpl.s   Enemy_FormationWaveCheckVerticalSpeed
                neg.l   d0
Enemy_FormationWaveCheckVerticalSpeed:                  ; was: loc_3304A
                cmpi.l  #$10000,d0
                bne.s   Enemy_FormationWaveCheckLeftBoundary
                neg.l   $5C(a5)
Enemy_FormationWaveCheckLeftBoundary:                   ; was: loc_33056
                bra.w   Enemy_FormationWaveDeactivatePastLeftBoundary
; End of function Enemy_FormationWaveBeginVerticalOscillation
; Delays by formation offset, then selects positive vertical acceleration
Enemy_FormationWaveBeginPositiveAcceleratedPath:        ; was: sub_3305A
                move.l  #$FFFEC000,$18(a5)
                subq.w  #1,$5C(a5)
                bpl.w   Enemy_FormationWaveReturn
                move.l  #$1C0,$5C(a5)
                addq.w  #2,4(a5)
; Applies the selected vertical acceleration and checks the left boundary
Enemy_FormationWaveUpdateAcceleratedPath:               ; was: loc_33076
                move.l  $5C(a5),d0
                add.l   d0,$1C(a5)
                bra.w   Enemy_FormationWaveDeactivatePastLeftBoundary
; End of function Enemy_FormationWaveBeginPositiveAcceleratedPath
; Delays by formation offset, then selects negative vertical acceleration
Enemy_FormationWaveBeginNegativeAcceleratedPath:        ; was: sub_33082
                move.l  #$FFFEC000,$18(a5)
                subq.w  #1,$5C(a5)
                bpl.w   Enemy_FormationWaveReturn
                move.l  #$FFFFFE40,$5C(a5)
                subq.w  #2,4(a5)
                bra.s   Enemy_FormationWaveUpdateAcceleratedPath
; ---------------------------------------------------------------------------
                addq.w  #2,4(a5)
Enemy_FormationWaveReturn:                              ; was: locret_330A4
                                        ; Enemy_FormationWaveDeactivatePastLeftBoundary+6   j
                rts
; End of function Enemy_FormationWaveBeginNegativeAcceleratedPath
