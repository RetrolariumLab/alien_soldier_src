; Post-battle type-$494 reward-pickup emitter created by Wolf Garopa's stage transition
Boss_WolfGaropaRewardShowerMain:                        ; was: sub_32DFE
                move.w  4(a5),d0
                lea     Boss_WolfGaropaRewardShowerStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_WolfGaropaRewardShowerMain
; ---------------------------------------------------------------------------
Boss_WolfGaropaRewardShowerStates:  dc.w    Boss_WolfGaropaRewardShowerInit-*  ; was: off_32E0A
                dc.w    Boss_WolfGaropaSpawnFiniteRewardPickups-*
                dc.w    Boss_WolfGaropaSpawnTimedRewardPickups-*

; Initializes the reward count and selects the stage-specific emission mode
Boss_WolfGaropaRewardShowerInit:                        ; was: sub_32E10
                move.w  #$100,2(a5)
                move.w  #$A300,$E(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                cmpi.w  #$10,(StageTableIndex).w
                bne.w   Entity_UpdateReturn
                move.w  #$18,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_WolfGaropaRewardShowerInit
; Emits sixteen falling pickups from a fixed point, one every eight ticks
Boss_WolfGaropaSpawnFiniteRewardPickups:                ; was: sub_32E3C
                move.w  #$1D0,$10(a5)
                move.w  #$120,$14(a5)
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                subq.w  #1,$48(a5)
                move.w  #$F,d0
                jsr     (Pickup_SelectRandomSize).l
                ori.w   #$800,2(a0)
                move.l  #$FFF78000,$18(a0)
                jsr     (RandomNumber).l
                andi.w  #$70,d0                         ; 'p'
                addi.w  #$D0,d0
                move.w  d0,$14(a0)
                move.w  #$1D0,$10(a0)
                tst.w   $48(a5)
                bne.w   Entity_UpdateReturn
Boss_WolfGaropaRemoveRewardEmitter:                     ; was: loc_32E9A
                move.w  #$1000,2(a5)
                rts
; End of function Boss_WolfGaropaSpawnFiniteRewardPickups
; Emits a countdown-controlled stream of stationary random pickups
Boss_WolfGaropaSpawnTimedRewardPickups:                 ; was: sub_32EA2
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_WolfGaropaAdvanceRewardCountdown
                move.w  #$F,d0
                jsr     (Pickup_SelectRandomSize).l
                jsr     (RandomNumber).l
                andi.w  #$70,d0                         ; 'p'
                addi.w  #$D0,d0
                move.w  d0,$14(a0)
                move.w  #$1D0,$10(a0)
Boss_WolfGaropaAdvanceRewardCountdown:                  ; was: loc_32ED8
                subq.w  #1,$48(a5)
                beq.s   Boss_WolfGaropaRemoveRewardEmitter
                rts
; End of function Boss_WolfGaropaSpawnTimedRewardPickups
