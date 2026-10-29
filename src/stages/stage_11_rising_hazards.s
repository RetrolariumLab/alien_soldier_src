; Main handler for the Stage 11 submerged launcher
Stage11_RisingHazardLauncherMain:                       ; was: sub_30D90
                cmpi.w  #$14,4(a5)
                bcc.s   Stage11_RisingHazardLauncherDispatch
                tst.w   $24(a5)
                bpl.w   Stage11_RisingHazardLauncherDispatch
                move.w  #$14,4(a5)
Stage11_RisingHazardLauncherDispatch:
                move.w  4(a5),d0
                lea     Stage11_RisingHazardLauncherStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage11_RisingHazardLauncherMain
; ---------------------------------------------------------------------------
Stage11_RisingHazardLauncherStates:
                dc.w    Stage11_RisingHazardLauncherInit-*
                dc.w    Stage11_RisingHazardLauncherRise-*
                dc.w    Stage11_RisingHazardLauncherEmit-*
                dc.w    Stage11_RisingHazardLauncherReverseMotion-*
                dc.w    Stage11_RisingHazardLauncherPauseAndRepeat-*
                dc.w    Stage11_RisingHazardLauncherBeginExit-*
                dc.w    Stage11_RisingHazardLauncherBrakeDescent-*
                dc.w    Stage11_RisingHazardLauncherCurveLeft-*
                dc.w    Stage11_RisingHazardLauncherCurveRight-*
                dc.w    Stage11_RisingHazardLauncherCurveLeftAndRestart-*
                dc.w    Stage11_RisingHazardLauncherBeginFinalDescent-*
                dc.w    Stage11_RisingHazardLauncherFinalDescent-*

; Initializes Stage 11 boss part
Stage11_RisingHazardLauncherInit:                       ; was: sub_30DCA
                move.w  #$CF00,2(a5)
                move.w  #$8C2,$E(a5)
                move.l  #Stage11_RisingHazardLauncherSpriteMapping,8(a5)
                move.b  #$3C,$20(a5)                    ; '<'
                move.w  #$64,$24(a5)                    ; 'd'
                move.b  #$C0,$21(a5)
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$26(a5)                    ; '('
                move.l  #$FFFD0000,$1C(a5)
                move.l  #$FFFE8000,$18(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherInit
; Boss part floating state
Stage11_RisingHazardLauncherRise:                       ; was: sub_30E1C
                addi.l  #$4000,$1C(a5)
                bne.w   Entity_UpdateReturn
                clr.l   $1C(a5)
                clr.l   $18(a5)
                move.w  #$20,$46(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherRise
; Boss part spawns projectile
Stage11_RisingHazardLauncherEmit:                       ; was: sub_30E3C
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Stage11_RisingHazardLauncherBeginDescent
                move.w  #$8F00,2(a0)
                move.w  #$38C,(a0)
                move.w  $10(a5),$10(a0)
                subi.w  #$18,$10(a0)
                move.w  $14(a5),$14(a0)
                subi.w  #$14,$14(a0)
                move.w  $5E(a5),$5E(a0)
                clr.w   4(a0)
Stage11_RisingHazardLauncherBeginDescent:
                move.l  #$40000,$1C(a5)
                move.l  #$30000,$18(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherEmit
; Initializes falling state
Stage11_RisingHazardLauncherReverseMotion:              ; was: sub_30E86
                move.l  #$FFFC0000,$1C(a5)
                move.l  #$FFFD0000,$18(a5)
                move.w  #4,$44(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherReverseMotion
; Delays before next fall iteration
Stage11_RisingHazardLauncherPauseAndRepeat:             ; was: sub_30EA2
                clr.l   $1C(a5)
                clr.l   $18(a5)
                subq.w  #1,$44(a5)
                bne.w   Entity_UpdateReturn
                subq.w  #1,$46(a5)
                beq.s   Stage11_RisingHazardLauncherFinishEmissionCycle
                subq.w  #4,4(a5)
                rts
; ---------------------------------------------------------------------------
Stage11_RisingHazardLauncherFinishEmissionCycle:
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherPauseAndRepeat
; Set vertical and horizontal velocity for boss part
Stage11_RisingHazardLauncherBeginExit:                  ; was: sub_30EC4
                move.l  #$30000,$1C(a5)
                move.l  #$18000,$18(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherBeginExit
; Decelerate vertical velocity until stopped then wait
Stage11_RisingHazardLauncherBrakeDescent:               ; was: sub_30EDA
                subi.l  #$4000,$1C(a5)
                bne.w   Entity_UpdateReturn
                clr.l   $18(a5)
                move.w  #$20,$46(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherBrakeDescent
; Decelerates upward movement with timer countdown for Jetsripper boss part
Stage11_RisingHazardLauncherCurveLeft:                  ; was: sub_30EF6
                subi.l  #$A00,$18(a5)
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$40,$46(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherCurveLeft
; Accelerates downward movement with timer countdown for Jetsripper boss part
Stage11_RisingHazardLauncherCurveRight:                 ; was: sub_30F12
                addi.l  #$A00,$18(a5)
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$20,$46(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherCurveRight
; Decelerates upward and resets to initial movement state with specific velocities
Stage11_RisingHazardLauncherCurveLeftAndRestart:        ; was: sub_30F2E
                subi.l  #$A00,$18(a5)
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.l  #$FFFD0000,$1C(a5)
                move.l  #$FFFE8000,$18(a5)
                move.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherCurveLeftAndRestart
; Initializes downward velocity for Jetsripper boss part movement
Stage11_RisingHazardLauncherBeginFinalDescent:          ; was: sub_30F56
                clr.l   $18(a5)
                move.l  #$8000,$1C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardLauncherBeginFinalDescent
; Spawns projectiles periodically until Y position falls below 180h
Stage11_RisingHazardLauncherFinalDescent:               ; was: sub_30F68
                bsr.w   Stage11_RisingHazardLauncherFireUpward
                cmpi.w  #$180,$14(a5)
                bcs.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; End of function Stage11_RisingHazardLauncherFinalDescent
; Creates projectile every 4 frames and negates vertical velocity for upward firing
Stage11_RisingHazardLauncherFireUpward:                 ; was: sub_30F7E
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                bsr.w   Projectile_SpawnRandomAngleShot
                tst.l   $1C(a4)
                bmi.w   Entity_UpdateReturn
                neg.l   $1C(a4)
                rts
; End of function Stage11_RisingHazardLauncherFireUpward
; State dispatcher for a rising Stage 11 hazard
Stage11_RisingHazardMain:                               ; was: sub_30FA6
                move.w  4(a5),d0
                lea     Stage11_RisingHazardStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage11_RisingHazardMain
; ---------------------------------------------------------------------------
Stage11_RisingHazardStates:
                dc.w    Stage11_RisingHazardInit-*
                dc.w    Stage11_RisingHazardRiseAndReact-*

; Boss part state 1 initialization
Stage11_RisingHazardInit:                               ; was: sub_30FB6
                jsr     (RandomNumber).l
                andi.w  #6,d0
                move.w  d0,$40(a5)
                bsr.w   Stage11_RisingHazardAdvancePalette
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #$800,$24(a5)
                move.b  #$C0,$21(a5)
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$26(a5)                    ; '('
                move.w  $5E(a5),d0
                move.l  Stage11_RisingHazardMotionTable(pc,d0.w),$1C(a5)
                move.l  Stage11_RisingHazardMotionTable+$10(pc,d0.w),$18(a5)
                move.l  Stage11_RisingHazardMotionTable+$20(pc,d0.w),$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage11_RisingHazardInit
; ---------------------------------------------------------------------------
Stage11_RisingHazardMotionTable:
                dc.l    $FFFB0000, $FFFC0000
                dc.l    $FFFD0000, $FFFE0000
                dc.l    $FFFD0000, $FFFD8000
                dc.l    $FFFE0000, $FFFE8000
                dc.l    $1800, $1400
                dc.l    $1000, $C00

; Falls with applied velocity while firing projectiles until Y position reaches 180h
Stage11_RisingHazardRiseAndReact:                       ; was: sub_31048
                bsr.w   Stage11_RisingHazardAdvancePaletteEveryFourthFrame
                bsr.w   Stage11_RisingHazardReactToHit
                move.l  $48(a5),d0
                add.l   d0,$1C(a5)
                cmpi.w  #$180,$14(a5)
                bcs.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; End of function Stage11_RisingHazardRiseAndReact
; Checks frame counter mod 4 for timing projectile spawn
Stage11_RisingHazardAdvancePaletteEveryFourthFrame:     ; was: sub_3106A
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Entity_UpdateReturn
; End of function Stage11_RisingHazardAdvancePaletteEveryFourthFrame
; Updates boss part palette cycle
Stage11_RisingHazardAdvancePalette:                     ; was: sub_31076
                move.w  $40(a5),d0
                addq.w  #2,d0
                cmpi.w  #6,d0
                bcs.s   Stage11_RisingHazardStorePalette
                clr.w   d0
Stage11_RisingHazardStorePalette:
                move.w  d0,$40(a5)
                move.w  Stage11_RisingHazardPaletteAttributes(pc,d0.w),$E(a5)
                rts
; End of function Stage11_RisingHazardAdvancePalette
; ---------------------------------------------------------------------------
Stage11_RisingHazardPaletteAttributes:
                dc.w    $2109, $2112, $211B

; Spawns projectile at random angle after taking damage from specific hit flags
Stage11_RisingHazardReactToHit:                         ; was: sub_31096
                bclr    #6,$22(a5)
                bne.s   Stage11_RisingHazardEmitHitShot
                bclr    #7,$22(a5)
                bne.s   Stage11_RisingHazardEmitHitShot
                rts
; ---------------------------------------------------------------------------
Stage11_RisingHazardEmitHitShot:
                jsr     (RandomNumber).l
                andi.w  #$1FE,d0
                move.w  d0,d4
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                jsr     (Projectile_SpawnType1A8AtAngle).l
                jsr     (RandomNumber).l
                andi.w  #$F,d0
                bne.s   Stage11_RisingHazardRemove
                jsr     (RandomNumber).l
                move.w  #$F,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Stage11_RisingHazardRemove:
                move.w  #$1000,2(a5)
                rts
; End of function Stage11_RisingHazardReactToHit
