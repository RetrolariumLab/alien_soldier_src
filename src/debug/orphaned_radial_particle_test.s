; Orphaned radial-particle test controller with no released-ROM entry point
Debug_RadialParticleTestController:                     ; was: sub_2F1A2
                bsr.w   Debug_AdjustRadialParticleRadius
                move.w  4(a5),d0
                lea     Debug_RadialParticleTestStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Debug_RadialParticleTestController
; ---------------------------------------------------------------------------
Debug_RadialParticleTestStateTable: dc.w    Debug_RadialParticleTestInit-*  ; was: off_2F1B2
                dc.w    Debug_RadialParticleTestPrepareBurstState-*

; Initializes the test controller at a fixed screen position and radius
Debug_RadialParticleTestInit:                           ; was: sub_2F1B6
                move.w  #$C00,2(a5)
                move.w  #$18,$50(a5)
                move.w  #$120,$10(a5)
                move.w  #$F0,$14(a5)
                addq.w  #2,4(a5)
                rts
; End of function Debug_RadialParticleTestInit
; Prepares motion data for up to eight free slots using randomized angles
Debug_RadialParticleTestPrepareBurstState:              ; was: sub_2F1D4
                move.w  #7,d7
Debug_RadialParticleTestPrepareBurstLoop:               ; was: loc_2F1D8
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #$1FF,d0
                move.w  d0,$52(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                move.w  d0,$54(a5)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                move.w  d0,$56(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Debug_RadialParticleTestPrepareBurstReturn
                bsr.w   Debug_RadialParticleTestEmptySlotSetupHook
                lea     (Math_SineTable).l,a4
                move.w  $52(a5),d0
                andi.w  #$1FE,d0
                move.w  (a4,d0.w),d2
                move.w  -$80(a4,d0.w),d3
                muls.w  $50(a5),d2
                muls.w  $50(a5),d3
                swap    d2
                swap    d3
                move.w  d2,$4C(a0)
                move.w  d3,$4E(a0)
                move.w  $54(a5),d0
                add.w   $4C(a5),d0
                andi.w  #$1FE,d0
                muls.w  (a4,d0.w),d2
                asl.l   #2,d2
                move.w  $56(a5),d0
                add.w   $4E(a5),d0
                andi.w  #$1FE,d0
                muls.w  (a4,d0.w),d3
                asl.l   #2,d3
                tst.l   d2
                bne.s   Debug_RadialParticleTestStoreSlotMotion
                tst.l   d3
                bne.s   Debug_RadialParticleTestStoreSlotMotion
                move.w  #$1000,2(a0)
                bra.w   Debug_RadialParticleTestNextBurstSlot
; ---------------------------------------------------------------------------
Debug_RadialParticleTestStoreSlotMotion:                ; was: loc_2F278
                                        ; Debug_RadialParticleTestPrepareBurstState+98   j
                move.w  a5,$4A(a0)
                move.w  $54(a5),$58(a0)
                move.w  $56(a5),$5A(a0)
                move.l  d2,$18(a0)
                move.l  d3,$1C(a0)
                asr.l   #4,d2
                asr.l   #4,d3
                move.l  d2,$50(a0)
                move.l  d3,$54(a0)
Debug_RadialParticleTestNextBurstSlot:                  ; was: loc_2F29C
                dbf     d7,Debug_RadialParticleTestPrepareBurstLoop
Debug_RadialParticleTestPrepareBurstReturn:             ; was: locret_2F2A0
                rts
; End of function Debug_RadialParticleTestPrepareBurstState
Debug_RadialParticleTestEmptySlotSetupHook:             ; was: nullsub_69
                rts
; End of function Debug_RadialParticleTestEmptySlotSetupHook

; Unreferenced setup routine for the radial-test particle sprite
Debug_SetupRadialTestParticleSprite:                    ; was: sub_2F2A4
                move.w  #$4E00,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  #$60,$20(a0)                    ; '`'
                move.w  #$480,$E(a0)
                move.l  #SharedCombatSpriteFrame35,8(a0)
                move.w  #8,$48(a0)
                rts
; End of function Debug_SetupRadialTestParticleSprite
; Lets held left/right input decrease or increase the test radius
Debug_AdjustRadialParticleRadius:                       ; was: sub_2F2D2
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_AdjustRadialParticleRadius_CheckLeft
                addq.w  #1,$50(a5)
Debug_AdjustRadialParticleRadius_CheckLeft:             ; was: loc_2F2DE
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_AdjustRadialParticleRadius_Return
                subq.w  #1,$50(a5)
Debug_AdjustRadialParticleRadius_Return:                ; was: locret_2F2EA
                rts
; End of function Debug_AdjustRadialParticleRadius
; Applies particle velocity and dispatches its two-state lifecycle
Debug_RadialTestParticleController:                     ; was: sub_2F2EC
                move.l  $50(a5),d0
                add.l   d0,$18(a5)
                move.l  $54(a5),d0
                add.l   d0,$1C(a5)
                move.w  4(a5),d0
                lea     Debug_RadialTestParticleStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Debug_RadialTestParticleController
; ---------------------------------------------------------------------------
Debug_RadialTestParticleStateTable: dc.w    Debug_RadialTestParticleInitialMotionState-*  ; was: off_2F308
                dc.w    Debug_RadialTestParticleFollowParentState-*

; Keeps the initial velocity for eight frames, then enables parent following
Debug_RadialTestParticleInitialMotionState:             ; was: sub_2F30C
                subq.w  #1,$48(a5)
                bne.s   Debug_RadialTestParticleInitialMotionState_Return
                bset    #7,2(a5)
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Debug_RadialTestParticleInitialMotionState_Return:      ; was: locret_2F322
                rts
; End of function Debug_RadialTestParticleInitialMotionState
; Recomputes particle motion when either parent angle changes, then expires it
Debug_RadialTestParticleFollowParentState:              ; was: sub_2F324
                movea.w $4A(a5),a0
                move.w  $4C(a0),d0
                cmp.w   $5C(a5),d0
                beq.s   Debug_RadialTestParticleFollowParentState_UpdateY
                move.w  d0,$5C(a5)
                move.w  $4C(a5),d2
                move.w  $58(a5),d0
                add.w   $4C(a0),d0
                andi.w  #$1FE,d0
                muls.w  (a4,d0.w),d2
                asl.l   #2,d2
                move.l  d2,$18(a5)
                asr.l   #4,d2
                move.l  d2,$50(a5)
Debug_RadialTestParticleFollowParentState_UpdateY:      ; was: loc_2F356
                move.w  $4E(a0),d0
                cmp.w   $5E(a5),d0
                beq.w   Debug_RadialTestParticleFollowParentState_CheckLifetime
                move.w  d0,$5E(a5)
                move.w  $4E(a5),d3
                move.w  $5A(a5),d0
                add.w   $4E(a0),d0
                andi.w  #$1FE,d0
                muls.w  (a4,d0.w),d3
                asl.l   #2,d3
                move.l  d3,$1C(a5)
                asr.l   #4,d3
                move.l  d3,$54(a5)
Debug_RadialTestParticleFollowParentState_CheckLifetime:  ; was: loc_2F386
                subq.w  #1,$48(a5)
                bne.s   Debug_RadialTestParticleFollowParentState_Return
                move.w  #$1000,2(a5)
Debug_RadialTestParticleFollowParentState_Return:       ; was: locret_2F392
                rts
; End of function Debug_RadialTestParticleFollowParentState
Debug_RadialParticleTestTrailingNoOp:                   ; was: nullsub_70
                rts
; End of function Debug_RadialParticleTestTrailingNoOp
